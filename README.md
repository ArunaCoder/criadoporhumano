# Projeto de Treinamento - TypeScript Configuration

Este projeto foi criado para treinar e testar diferentes configurações do TypeScript.

## 📋 Passos Iniciais

### 1️⃣ Inicializar o Projeto Node.js

```bash
npm init -y
```

Este comando cria o arquivo `package.json` com configurações padrão.

### 2️⃣ Instalar o TypeScript

```bash
npm install --save-dev typescript
npm install --save-dev @types/node
npm install --save-dev ts-node
```

- **typescript**: O compilador TypeScript
- **@types/node**: Definições de tipos para Node.js
- **ts-node**: Para executar arquivos TypeScript diretamente sem compilar

### 3️⃣ Criar a Estrutura de Pastas

```bash
mkdir src
mkdir dist
```

- **src/**: Pasta para arquivos TypeScript (.ts)
- **dist/**: Pasta para arquivos JavaScript compilados (.js)

### 4️⃣ Criar o arquivo tsconfig.json

```bash
npx tsc --init
```

Ou crie manualmente o arquivo `tsconfig.json` na raiz do projeto:

```json
{
  "compilerOptions": {
    /* Configurações Básicas */
    "target": "ES2020", // Versão do JavaScript de saída
    "module": "commonjs", // Sistema de módulos
    "lib": ["ES2020"], // Bibliotecas incluídas

    /* Diretórios */
    "rootDir": "./src", // Pasta dos arquivos fonte
    "outDir": "./dist", // Pasta de saída da compilação

    /* Verificações de Tipo Estritas */
    "strict": true, // Habilita todas verificações estritas
    "noImplicitAny": true, // Erro em expressões com tipo 'any' implícito
    "strictNullChecks": true, // Verificação estrita de null/undefined
    "strictFunctionTypes": true, // Verificação estrita de tipos de função
    "strictPropertyInitialization": true, // Propriedades de classe devem ser inicializadas

    /* Verificações Adicionais */
    "noUnusedLocals": true, // Erro em variáveis locais não utilizadas
    "noUnusedParameters": true, // Erro em parâmetros não utilizados
    "noImplicitReturns": true, // Erro se nem todos caminhos retornam valor
    "noFallthroughCasesInSwitch": true, // Erro em case sem break

    /* Interoperabilidade */
    "esModuleInterop": true, // Compatibilidade com módulos ES6
    "forceConsistentCasingInFileNames": true, // Consistência em nomes de arquivos

    /* Outras */
    "skipLibCheck": true, // Pular verificação de tipos em .d.ts
    "resolveJsonModule": true // Permite importar arquivos .json
  },
  "include": ["src/**/*"], // Arquivos a incluir
  "exclude": ["node_modules", "dist"] // Arquivos a excluir
}
```

### 5️⃣ Adicionar Scripts no package.json

Adicione os seguintes scripts na seção `"scripts"` do `package.json`:

```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "watch": "tsc --watch",
    "clean": "rm -rf dist"
  }
}
```

**Explicação dos scripts:**

- `build`: Compila TypeScript para JavaScript
- `start`: Executa o arquivo compilado
- `dev`: Executa diretamente o TypeScript (para desenvolvimento)
- `watch`: Compila automaticamente quando há alterações
- `clean`: Remove a pasta dist

### 6️⃣ Criar Arquivo de Exemplo

Crie o arquivo `src/index.ts`:

```typescript
// Exemplo básico de TypeScript
function saudacao(nome: string): string {
  return `Olá, ${nome}! Bem-vindo ao TypeScript!`;
}

const usuario: string = "Desenvolvedor";
console.log(saudacao(usuario));

// Exemplo com tipos
interface Pessoa {
  nome: string;
  idade: number;
  email?: string; // opcional
}

const pessoa: Pessoa = {
  nome: "João",
  idade: 30,
};

console.log(pessoa);

// Exemplo com classe
class Calculator {
  somar(a: number, b: number): number {
    return a + b;
  }

  subtrair(a: number, b: number): number {
    return a - b;
  }
}

const calc = new Calculator();
console.log("Soma:", calc.somar(10, 5));
console.log("Subtração:", calc.subtrair(10, 5));
```

### 7️⃣ Compilar e Executar

```bash
# Compilar TypeScript para JavaScript
npm run build

# Executar o arquivo compilado
npm start

# OU executar diretamente (desenvolvimento)
npm run dev
```

## 🧪 Exercícios de Configuração do tsconfig.json

### Exercício 1: Testar `strict`

1. Mude `"strict": false` no tsconfig.json
2. Crie um código que aceite `any` implicitamente
3. Compare o comportamento

### Exercício 2: Testar `target`

1. Mude `"target"` para diferentes valores: "ES5", "ES2015", "ES2020", "ESNext"
2. Use recursos modernos como arrow functions, async/await
3. Veja como o código compilado muda

### Exercício 3: Testar `noUnusedLocals`

1. Crie variáveis não utilizadas
2. Veja os erros aparecerem
3. Experimente desabilitar a opção

### Exercício 4: Testar `strictNullChecks`

```typescript
function exemplo(valor: string | null) {
  console.log(valor.toUpperCase()); // Erro com strictNullChecks
}
```

## 📚 Configurações Importantes para Experimentar

| Opção            | Descrição                      | Valores                     |
| ---------------- | ------------------------------ | --------------------------- |
| `target`         | Versão JS de saída             | ES5, ES2015, ES2020, ESNext |
| `module`         | Sistema de módulos             | commonjs, es6, esnext       |
| `strict`         | Todas verificações estritas    | true, false                 |
| `sourceMap`      | Gerar arquivos .map para debug | true, false                 |
| `declaration`    | Gerar arquivos .d.ts           | true, false                 |
| `removeComments` | Remover comentários do output  | true, false                 |

## 🔍 Comandos Úteis

```bash
# Ver versão do TypeScript
npx tsc --version

# Ver ajuda do compilador
npx tsc --help

# Compilar arquivo específico
npx tsc src/index.ts

# Verificar erros sem compilar
npx tsc --noEmit

# Modo watch (recompila automaticamente)
npx tsc --watch
```

## 📖 Recursos Adicionais

- [Documentação Oficial do TypeScript](https://www.typescriptlang.org/docs/)
- [TSConfig Reference](https://www.typescriptlang.org/tsconfig)
- [TypeScript Playground](https://www.typescriptlang.org/play)

## 🎯 Próximos Passos

1. Experimentar com diferentes configurações no tsconfig.json
2. Criar mais arquivos de exemplo na pasta `src/`
3. Testar recursos avançados: Generics, Decorators, Utility Types
4. Adicionar linting com ESLint
5. Configurar testes com Jest
