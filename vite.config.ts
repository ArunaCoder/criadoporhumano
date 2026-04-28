import path from "path";

import { defineConfig } from "vite";

export default defineConfig({
  // 1. Configuração de Resolução (Aliases)
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },

  // 2. Configurações do Servidor de Desenvolvimento
  server: {
    port: 3000, // Define uma porta fixa para facilitar o acesso
    strictPort: true, // Se a porta 3000 estiver ocupada, ele não pula para a 3001 (evita confusão)
  },

  // 3. Configurações de Build (Produção)
  build: {
    outDir: "dist",
    sourcemap: true, // Mantém o mapeamento para depuração, conforme seu tsconfig
    minify: "esbuild", // Usa o Esbuild para minificar, garantindo alta performance
    emptyOutDir: true, // Limpa a pasta dist antes de cada build para evitar arquivos órfãos
  },
});
