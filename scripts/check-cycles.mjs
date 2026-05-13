#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Múltiplos diretórios para verificar (workspaces)
const SRC_DIRS = [
  path.resolve(__dirname, "../frontend/src"),
  path.resolve(__dirname, "../sdk/src"),
  path.resolve(__dirname, "../browser-extension/src"),
].filter((dir) => fs.existsSync(dir));

const LOG_FILE = path.resolve(__dirname, "../cycles-debug.log");
const EXTENSIONS = [".ts", ".tsx", ".js", ".jsx"];

// Verifica flags de linha de comando
const VERBOSE =
  process.argv.includes("--verbose") || process.argv.includes("--debug");

/**
 * Sistema de logging
 */
class Logger {
  constructor(logFile, verbose) {
    this.logFile = logFile;
    this.verbose = verbose;
    this.logs = [];
    this.stats = {
      filesScanned: 0,
      importsFound: 0,
      importsResolved: 0,
      importsSkipped: 0,
      cyclesDetected: 0,
    };
  }

  log(message) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${message}`;
    this.logs.push(logEntry);

    if (this.verbose) {
      console.log(message);
    }
  }

  section(title) {
    const separator = "=".repeat(60);
    this.log(`\n${separator}`);
    this.log(`=== ${title}`);
    this.log(separator);
  }

  writeToFile() {
    const content = `${this.logs.join("\n")}\n\n${this.getStatsReport()}`;
    fs.writeFileSync(this.logFile, content, "utf-8");
  }

  getStatsReport() {
    return `
=== ESTATÍSTICAS ===
Arquivos escaneados: ${this.stats.filesScanned}
Imports encontrados: ${this.stats.importsFound}
Imports resolvidos: ${this.stats.importsResolved}
Imports ignorados: ${this.stats.importsSkipped}
Ciclos detectados: ${this.stats.cyclesDetected}
`;
  }
}

const logger = new Logger(LOG_FILE, VERBOSE);

/**
 * Lê recursivamente todos os arquivos do diretório
 */
function getAllFiles(dir, files = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const projectRoot = path.resolve(__dirname, "..");

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      logger.log(`[SCAN] Diretório: ${path.relative(projectRoot, fullPath)}/`);
      getAllFiles(fullPath, files);
    } else if (EXTENSIONS.includes(path.extname(entry.name))) {
      logger.log(`[FOUND] ${path.relative(projectRoot, fullPath)}`);
      logger.stats.filesScanned++;
      files.push(fullPath);
    }
  }

  return files;
}

/**
 * Extrai imports de um arquivo
 */
function extractImports(filePath) {
  const content = fs.readFileSync(filePath, "utf-8");
  const imports = new Set();
  const _lines = content.split("\n");

  // Padrões de import ES6
  const importPatterns = [
    // import something from './path'
    /import\s+.*?\s+from\s+['"](.+?)['"]/g,
    // import './path'
    /import\s+['"](.+?)['"]/g,
    // export ... from './path'
    /export\s+.*?\s+from\s+['"](.+?)['"]/g,
    // import type/import { type }
    /import\s+type\s+.*?\s+from\s+['"](.+?)['"]/g,
  ];

  for (const pattern of importPatterns) {
    let match = pattern.exec(content);
    while (match !== null) {
      const importPath = match[1];

      // Ignora imports de node_modules ou externos
      if (!importPath.startsWith(".") && !importPath.startsWith("@/")) {
        logger.log(`  [SKIP] ${importPath} (externo)`);
        logger.stats.importsSkipped++;
        match = pattern.exec(content);
        continue;
      }

      imports.add(importPath);
      logger.log(`  [IMPORT] ${importPath}`);
      logger.stats.importsFound++;
      match = pattern.exec(content);
    }
  }

  return Array.from(imports);
}

/**
 * Resolve o caminho do import para caminho absoluto
 */
function resolveImportPath(fromFile, importPath) {
  const fromDir = path.dirname(fromFile);
  const _originalImport = importPath;
  const projectRoot = path.resolve(__dirname, "..");

  logger.log(`  [RESOLVE] ${importPath}`);

  let resolved;

  // Trata alias @/ como src/ relativo ao workspace
  if (importPath.startsWith("@/")) {
    logger.log("    [ALIAS] Convertendo @/ para src/ do workspace");
    importPath = importPath.replace("@/", "");

    // Encontra o workspace do arquivo atual
    const workspace = SRC_DIRS.find((dir) => fromFile.startsWith(dir));
    if (workspace) {
      resolved = path.resolve(workspace, importPath);
    } else {
      resolved = path.resolve(fromDir, importPath);
    }
  } else {
    // Import relativo
    logger.log(`    [RELATIVE] Base: ${path.relative(projectRoot, fromDir)}/`);
    resolved = path.resolve(fromDir, importPath);
  }

  // Tenta adicionar extensões se necessário
  if (fs.existsSync(resolved)) {
    const stat = fs.statSync(resolved);
    if (stat.isFile()) {
      logger.log(
        `    [SUCCESS] Arquivo encontrado: ${path.relative(projectRoot, resolved)}`,
      );
      logger.stats.importsResolved++;
      return resolved;
    }
    if (stat.isDirectory()) {
      // Tenta index.*
      for (const ext of EXTENSIONS) {
        const indexPath = path.join(resolved, `index${ext}`);
        logger.log(`    [TRY] ${path.relative(projectRoot, indexPath)}`);
        if (fs.existsSync(indexPath)) {
          logger.log("    [SUCCESS] Index encontrado");
          logger.stats.importsResolved++;
          return indexPath;
        }
      }
    }
  }

  // Tenta adicionar extensões
  for (const ext of EXTENSIONS) {
    const withExt = `${resolved}${ext}`;
    logger.log(`    [TRY] ${path.relative(projectRoot, withExt)}`);
    if (fs.existsSync(withExt)) {
      logger.log(`    [SUCCESS] Arquivo encontrado com extensão ${ext}`);
      logger.stats.importsResolved++;
      return withExt;
    }
  }

  logger.log("    [NOT FOUND] Arquivo não existe no projeto");
  logger.stats.importsSkipped++;
  return resolved;
}

/**
 * Constrói o grafo de dependências
 */
function buildDependencyGraph(files) {
  const graph = new Map();
  const projectRoot = path.resolve(__dirname, "..");

  for (const file of files) {
    logger.log(`\n[NODE] ${path.relative(projectRoot, file)}`);
    const imports = extractImports(file);
    const dependencies = [];

    for (const imp of imports) {
      const resolvedPath = resolveImportPath(file, imp);

      // Só adiciona se o arquivo resolvido existe no nosso conjunto
      if (files.includes(resolvedPath)) {
        dependencies.push(resolvedPath);
        logger.log(`  [EDGE] -> ${path.relative(projectRoot, resolvedPath)}`);
      }
    }

    graph.set(file, dependencies);
  }

  return graph;
}

/**
 * Detecta ciclos usando DFS (Depth-First Search)
 */
function detectCycles(graph) {
  const visited = new Set();
  const recursionStack = new Set();
  const cycles = [];
  const projectRoot = path.resolve(__dirname, "..");

  function dfs(node, currentPath = []) {
    const indent = "  ".repeat(currentPath.length);
    logger.log(`${indent}[VISIT] ${path.relative(projectRoot, node)}`);

    if (recursionStack.has(node)) {
      // Encontrou um ciclo!
      logger.log(`${indent}[CYCLE DETECTED!] Nó já está na pilha de recursão`);
      const cycleStart = currentPath.indexOf(node);
      const cycle = currentPath.slice(cycleStart).concat(node);
      cycles.push(cycle);

      const cyclePath = cycle
        .map((f) => path.relative(projectRoot, f))
        .join(" -> ");
      logger.log(`${indent}[CYCLE] ${cyclePath}`);
      logger.stats.cyclesDetected++;
      return;
    }

    if (visited.has(node)) {
      logger.log(`${indent}[SKIP] Já visitado anteriormente`);
      return;
    }

    visited.add(node);
    recursionStack.add(node);
    currentPath.push(node);

    const dependencies = graph.get(node) || [];
    if (dependencies.length > 0) {
      logger.log(
        `${indent}[RECURSE] Explorando ${dependencies.length} dependência(s)`,
      );
    }

    for (const dep of dependencies) {
      dfs(dep, [...currentPath]);
    }

    recursionStack.delete(node);
  }

  // Executa DFS para cada nó
  for (const node of graph.keys()) {
    if (!visited.has(node)) {
      logger.log(
        `\n[DFS] Iniciando busca a partir de: ${path.relative(projectRoot, node)}`,
      );
      dfs(node);
    }
  }

  return cycles;
}

/**
 * Formata o caminho do arquivo para exibição
 */
function formatPath(filePath) {
  const projectRoot = path.resolve(__dirname, "..");
  return path.relative(projectRoot, filePath);
}

/**
 * Remove ciclos duplicados
 */
function deduplicateCycles(cycles) {
  const normalized = cycles.map((cycle) => {
    const sorted = [...cycle].sort();
    return sorted.join("|");
  });

  const unique = new Set(normalized);
  const indices = Array.from(unique).map((norm) => {
    return normalized.indexOf(norm);
  });

  return indices.map((i) => cycles[i]);
}

/**
 * Script principal
 */
function main() {
  console.log("🔍 Verificando dependências circulares...\n");

  if (VERBOSE) {
    console.log("📝 Modo verbose ativado - gerando log detalhado\n");
  }

  logger.section("INICIALIZAÇÃO");
  logger.log(`Workspaces: ${SRC_DIRS.length}`);
  for (const dir of SRC_DIRS) {
    logger.log(`  - ${dir}`);
  }
  logger.log(`Arquivo de log: ${LOG_FILE}`);
  logger.log(`Extensões suportadas: ${EXTENSIONS.join(", ")}`);

  if (SRC_DIRS.length === 0) {
    const error = "Nenhum diretório src/ encontrado nos workspaces";
    logger.log(`[ERROR] ${error}`);
    logger.writeToFile();
    console.error(`❌ ${error}`);
    process.exit(1);
  }

  // 1. Busca todos os arquivos de todos os workspaces
  logger.section("DESCOBERTA DE ARQUIVOS");

  const files = [];
  SRC_DIRS.forEach((dir) => {
    logger.log(`Iniciando varredura em: ${dir}`);
    getAllFiles(dir, files);
  });

  console.log(`📁 Arquivos encontrados: ${files.length}`);

  logger.log(`\n[SUMMARY] Total de arquivos: ${files.length}`);

  if (files.length === 0) {
    logger.log("[INFO] Nenhum arquivo para verificar");
    logger.writeToFile();
    console.log("✅ Nenhum arquivo para verificar");
    process.exit(0);
  }

  // 2. Constrói o grafo
  logger.section("EXTRAÇÃO DE IMPORTS E CONSTRUÇÃO DO GRAFO");
  const graph = buildDependencyGraph(files);

  logger.log(`\n[SUMMARY] Grafo construído com ${graph.size} nós`);

  // 3. Detecta ciclos
  logger.section("DETECÇÃO DE CICLOS (DFS)");
  const cycles = detectCycles(graph);
  const uniqueCycles = deduplicateCycles(cycles);

  logger.section("RESULTADOS");
  logger.log(`Ciclos detectados (brutos): ${cycles.length}`);
  logger.log(`Ciclos únicos: ${uniqueCycles.length}`);

  // 4. Salva o log
  logger.writeToFile();
  console.log(
    `\n📄 Log detalhado salvo em: ${path.relative(process.cwd(), LOG_FILE)}\n`,
  );

  // 5. Reporta resultados
  if (uniqueCycles.length === 0) {
    console.log("✅ Nenhuma dependência circular detectada!\n");
    process.exit(0);
  }

  console.log(
    `❌ ${uniqueCycles.length} dependência(s) circular(es) detectada(s):\n`,
  );

  uniqueCycles.forEach((cycle, index) => {
    console.log(`Ciclo ${index + 1}:`);
    cycle.forEach((file, i) => {
      const formattedPath = formatPath(file);
      const arrow = i < cycle.length - 1 ? " → " : "";
      console.log(`  ${formattedPath}${arrow}`);
    });
    console.log("");
  });

  process.exit(1);
}

main();
