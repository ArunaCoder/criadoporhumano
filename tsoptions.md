# Guia de Configurações do tsconfig.json

Este documento lista todas as opções do seu arquivo, seguindo a ordem original.

### **File Layout**

1. **`rootDir`: "./src"** (Inativa)
   Define o diretório raiz dos arquivos de entrada. Ajuda a manter a estrutura de pastas ao compilar.
2. **`outDir`: "./dist"** (Inativa)
   Define o diretório de saída onde os arquivos compilados serão armazenados.

#### Explicação: rootDir e outDir

##### 1. rootDir: "./src" (Inativa)

Esta opção define onde reside o código-fonte principal do projeto. Ela serve para o TypeScript entender qual a base da estrutura de pastas que ele deve replicar na saída.

- **Quando deve estar ativa:** Deve ser usada quando você quer garantir que a estrutura da pasta de distribuição (saída) seja uma cópia fiel da sua pasta de origem. Se você colocar `./src`, o compilador ignora pastas externas (como testes ou scripts de build) e foca apenas no que importa para o funcionamento do sistema.
- **Se estiver inativa:** O TypeScript tenta adivinhar qual é a pasta raiz. Se você importar um arquivo que está fora da pasta principal por acidente, o compilador pode mudar toda a hierarquia da pasta de saída para tentar incluir esse arquivo, o que geralmente quebra os caminhos (imports) do código rodando em produção.

##### 2. outDir: "./dist" (Inativa)

Esta opção determina para qual diretório o TypeScript deve enviar os arquivos transformados em JavaScript após a compilação.

- **Quando deve estar ativa:** Essencial em praticamente qualquer projeto. Ela permite separar o ambiente de desenvolvimento (TypeScript) do ambiente de execução (JavaScript). Manter os arquivos compilados em uma pasta isolada como `./dist` facilita o deploy, a limpeza do projeto e a organização do controle de versão (.gitignore).
- **Se estiver inativa:** O TypeScript gera o arquivo `.js` no mesmo local onde está o arquivo `.ts`. Com o tempo, a sua pasta de código-fonte fica entulhada de arquivos duplicados, tornando a manutenção manual e a busca de arquivos muito mais difíceis.

---

#### Comportamento na Prática

**Se estiverem ativas:** Um arquivo em `src/banco/conexao.ts` será compilado para `dist/banco/conexao.js`. Sua pasta de origem fica limpa, contendo apenas o que você escreve.

**Se estiverem inativas:** O mesmo arquivo `src/banco/conexao.ts` gerará um `src/banco/conexao.js` exatamente ao lado dele. O código fonte e o código de execução ficam misturados no mesmo diretório.

### **Environment Settings**

3. **`module`: "nodenext"** (Ativa)
   Especifica o sistema de geração de módulos. "nodenext" é recomendado para Node.js moderno.
4. **`target`: "esnext"** (Ativa)
   Define a versão do JavaScript para a qual o código será compilado (a mais recente).
5. **`types`: []** (Ativa)
   Lista de pacotes de declaração de tipos a serem incluídos. Vazio limita a inclusão automática.
6. **`lib`: ["esnext"]** (Inativa)
   Define quais bibliotecas de API de ambiente (como ESNext, DOM) o TS deve conhecer.
7. **`types`: ["node"]** (Inativa)
   Instrução específica para incluir tipos globais do Node.js.

### **Other Outputs**

8. **`sourceMap`: true** (Ativa)
   Gera arquivos `.map` que permitem depurar o código TS original no navegador ou IDE.
9. **`declaration`: true** (Ativa)
   Gera arquivos `.d.ts` (definições de tipo) para que o código possa ser usado em outros projetos TS.
10. **`declarationMap`: true** (Ativa)
    Gera um mapeamento para os arquivos de declaração, facilitando a navegação até o fonte original.

### **Stricter Typechecking Options**

11. **`noUncheckedIndexedAccess`: true** (Ativa)
    Adiciona `undefined` a qualquer acesso por índice, forçando a verificação de existência.
12. **`exactOptionalPropertyTypes`: true** (Ativa)
    Impede que propriedades opcionais recebam `undefined` explicitamente se não estiverem no contrato.

### **Style Options**

13. **`noImplicitReturns`: true** (Inativa)
    Garante que todas as ramificações de uma função retornem um valor.
14. **`noImplicitOverride`: true** (Inativa)
    Exige o modificador `override` ao sobrescrever métodos de classes pai.
15. **`noUnusedLocals`: true** (Inativa)
    Reporta erro para variáveis locais que não são utilizadas.
16. **`noUnusedParameters`: true** (Inativa)
    Reporta erro para parâmetros de função que não são utilizados.
17. **`noFallthroughCasesInSwitch`: true** (Inativa)
    Evita que um caso de um `switch` passe para o próximo sem um `break`.
18. **`noPropertyAccessFromIndexSignature`: true** (Inativa)
    Obriga o uso de colchetes para acessar campos definidos via assinatura de índice.

### **Recommended Options**

19. **`strict`: true** (Ativa)
    Ativa o conjunto principal de verificações rigorosas do TypeScript.
20. **`jsx`: "react-jsx"** (Ativa)
    Define como o JSX é transformado (otimizado para versões modernas do React).
21. **`verbatimModuleSyntax`: true** (Ativa)
    Mantém a sintaxe de módulos exatamente como escrita, removendo apenas os tipos.
22. **`isolatedModules`: true** (Ativa)
    Garante que cada arquivo possa ser transpilado independentemente.
23. **`noUncheckedSideEffectImports`: true** (Ativa)
    Verifica se imports de efeito colateral apontam para arquivos realmente existentes.
24. **`moduleDetection`: "force"** (Ativa)
    Trata todos os arquivos como módulos, mesmo que não tenham explicitamente imports/exports.
25. **`skipLibCheck`: true** (Ativa)
    Pula a verificação de tipos dos arquivos de definição na `node_modules` para ganhar velocidade.
