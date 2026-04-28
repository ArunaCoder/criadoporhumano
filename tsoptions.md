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

#### Explicação: module, target, types e lib

##### 3. module: "ESNext" (Ativa)

Esta opção define qual padrão de sistema de módulos (imports e exports) o TypeScript deve utilizar no código gerado.

- **Quando deve estar ativa:** É a escolha ideal para o desenvolvimento moderno de Frontend utilizando ferramentas como **Vite**, **Esbuild** ou **Webpak**. O valor "ESNext" garante que o TypeScript utilize a sintaxe de módulos mais atual do JavaScript (ECMAScript Modules), permitindo funcionalidades como o carregamento assíncrono de módulos e o _Tree Shaking_ (remoção de código morto), o que resulta em arquivos menores e mais rápidos para o usuário final.
- **Diferença para o "nodenext":** Enquanto o "nodenext" é focado em regras rígidas para execução direta no servidor Node.js (exigindo extensões de arquivo como `.js` nos imports), o "ESNext" oferece a flexibilidade necessária para o navegador e para o fluxo de trabalho com Bundlers, sendo a configuração padrão para quase todo o ecossistema Web moderno.
- **Se estiver inativa ou com valor antigo:** O TypeScript poderia converter seus `imports` modernos para padrões obsoletos (como `CommonJS` / `require()`). Isso impediria que ferramentas modernas como o Vite otimizassem o código e poderia causar erros de execução, já que os navegadores modernos e o servidor Rust esperam (ou lidam melhor com) o padrão ESM nativo.

##### 4. target: "esnext" (Ativa)

Esta opção determina para qual versão do JavaScript o código TypeScript será convertido.

- **Quando deve estar ativa:** Quando o ambiente de execução é moderno (Node.js 18+, navegadores recentes) e suporta as funcionalidades mais recentes do JavaScript. Com "esnext", o TypeScript não precisa transpilar código moderno (como async/await, optional chaining, etc.), resultando em código mais limpo e performático.
- **Se estiver inativa ou com outro valor:** Com valores como "es5" ou "es2015", o TypeScript converte todo o código moderno para sintaxe antiga, aumentando o tamanho dos arquivos e adicionando polyfills desnecessários. Use apenas se precisar suportar ambientes legados (como IE11).

##### 5. types: [] (Ativa)

Esta opção controla quais pacotes de tipos (`@types/*`) o TypeScript inclui automaticamente na compilação.

- **Quando deve estar ativa (vazia):** Quando você quer controle total sobre os tipos incluídos no projeto. Com um array vazio, o TypeScript não adiciona automaticamente tipos globais de pacotes instalados, evitando conflitos e poluição do escopo global. Isso é especialmente útil em projetos Node.js onde você não quer tipos do DOM ou do navegador.
- **Se estiver com valores:** Por exemplo, `["node", "jest"]` incluiria tipos específicos desses pacotes. Pode ser necessário quando você precisa de definições globais específicas, mas use com cuidado para não misturar ambientes (Node + Browser).
- **O exemplo do Node.js:** Sem os tipos do Node, o TypeScript não reconhece objetos globais como `process`, `__dirname` ou módulos nativos como `fs`. Ao definir `["node"]`, você "abre os olhos" do compilador para essas ferramentas específicas.
- **Vantagem do escopo limpo:** Usar o array vazio `[]` força o Autocomplete (IntelliSense) a ser mais preciso. Se você precisar de algo do Node, você o importa explicitamente (ex: `import process from 'node:process'`), mantendo o código mais seguro e portátil.
- **Se estiver inativa (comentada):** O comportamento padrão entra em ação e o TypeScript carrega **todos** os pacotes que encontrar dentro da sua pasta `node_modules/@types`. Isso facilita o início do projeto, mas pode deixar a checagem de tipos mais lenta e as sugestões do editor mais poluídas com funções que você nunca usará.

##### 6. lib: ["esnext"] (Inativa)

Esta opção especifica quais bibliotecas de API de ambiente o TypeScript deve reconhecer durante a verificação de tipos.

- **Quando deve estar ativa:** Quando você quer explicitar quais APIs estão disponíveis no ambiente. Por exemplo, `["esnext"]` diz ao TS que só APIs modernas do JavaScript estão disponíveis, sem APIs do navegador (DOM, BOM). Isso evita usar acidentalmente `document.querySelector()` em código Node.js.
- **Se estiver inativa:** O TypeScript infere automaticamente as libs com base no `target`. Com `target: "esnext"`, ele assume `lib: ["esnext"]` implicitamente. Pode deixar inativa se o padrão atender suas necessidades.
- **Segurança contra Execuções Inválidas:** Ativar esta opção e remover o `DOM` impede que o compilador aceite código que tentaria acessar objetos globais inexistentes no servidor (como `window`, `localStorage` ou `document`). Isso evita que erros do tipo `ReferenceError: document is not defined` cheguem ao ambiente de produção.
- **Isolamento de Ambiente:** Em arquiteturas de microsserviços ou sistemas que rodam em ambientes restritos (como Edge Functions ou Workers), restringir a `lib` garante que o desenvolvedor não utilize acidentalmente métodos que não estão disponíveis naquele runtime específico, garantindo que o código seja portável e seguro para aquele destino.
- **Prevenção de "Poluentes" Globais:** Ao desativar bibliotecas desnecessárias, você reduz a superfície de ataque de erros lógicos. Por exemplo, evitar que uma variável global chamada `name` (que existe no escopo `window` do navegador) seja usada acidentalmente em vez de uma variável local não definida, o que poderia causar comportamentos imprevisíveis.
- **Conclusão Final:** Para o seu caso (Frontend acessível pelo navegador), Inativo é a escolha mais equilibrada. A segurança no TypeScript vem mais de opções como strict: true e noImplicitAny do que da restrição da lib, a menos que você queira garantir que o código seja 100% universal (rode em qualquer lugar).

##### 7. types: ["node"] (Inativa)

[já abordado]

Sem tipos do navegador no escopo, o TypeScript alertaria se você tentar usar `document` ou `window` acidentalmente.

**Com configurações antigas (module: "commonjs", target: "es5", types: incluindo browser):**
O mesmo código seria transpilado para sintaxe verbosa com polyfills, e você poderia usar APIs do navegador sem avisos, causando erros em runtime no Node.js.

### **Other Outputs**

##### 8. sourceMap: true (Ativa)

Gera arquivos `.map` que permitem depurar o código TS original no navegador ou IDE.

- **Implicação no Desenvolvimento:** Essencial para produtividade. Sem isso, quando ocorrer um erro no navegador, o console mostrará a linha do erro no arquivo JavaScript (já transpilado e muitas vezes ilegível), e não no seu arquivo `.ts` original.
- **Implicação de Segurança:** Em produção, se você enviar os arquivos `.map` para o servidor público, qualquer pessoa poderá ver o seu código-fonte original através das ferramentas de desenvolvedor do navegador. Para sistemas sensíveis, recomenda-se gerar os mapas mas não subi-los para o servidor final, ou restringir o acesso a eles.

##### 9. declaration: true (Ativa)

Gera arquivos `.d.ts` (definições de tipo) para que o código possa ser usado em outros projetos TS.

- **Implicação na Reutilização:** Se o seu monolito crescer e você decidir extrair uma parte do código para uma biblioteca separada, esses arquivos são o que permitem que outros projetos entendam suas funções e classes com tipagem completa, sem precisar ler o código lógico.
- **Implicação no Rust:** Embora o Rust não leia arquivos `.d.ts` diretamente, ter essas definições claras facilita a criação de "bindings" ou interfaces de comunicação entre o seu Frontend TypeScript e o seu Backend Rust, servindo como uma documentação técnica rigorosa da estrutura de dados.

##### 10. declarationMap: true (Ativa)

Gera um mapeamento para os arquivos de declaração, facilitando a navegação até o fonte original.

- **Implicação na Manutenção:** Quando você está em um arquivo e usa o comando "Go to Definition" (F12) em uma função, o editor normalmente te levaria para o arquivo de tipos (`.d.ts`). Com o `declarationMap`, o editor pula direto para o arquivo fonte original (`.ts`).
- **Conexão com Projetos Grandes:** Em um monolito, isso economiza tempo precioso de navegação, permitindo que você entenda a implementação real de uma função rapidamente, em vez de ver apenas a assinatura do tipo dela.

### **Stricter Typechecking Options**

##### 11. noUncheckedIndexedAccess: true (Ativa)

Adiciona `undefined` a qualquer acesso por índice, forçando a verificação de existência.

- **Implicação na Segurança:** Resolve um dos maiores "pontos cegos" do TypeScript. Sem isso, se você acessar `lista[5]`, o TS assume que o valor existe e é do tipo esperado. Com esta opção, ele te obriga a tratar o caso onde o valor pode ser `undefined`. Isso previne o erro clássico de tentar acessar uma propriedade em um valor nulo (`Cannot read property 'x' of undefined`) em tempo de execução.
- **Impacto no Código:** O código fica mais "verboso", pois você precisará usar encadeamento opcional (`lista[5]?.nome`) ou verificações de `if (valor)`. Em um monolito que lida com dados vindos do Rust, isso garante que você trate listas vazias ou índices inexistentes com segurança antes de tentar renderizar algo na tela.

##### 12. exactOptionalPropertyTypes: true (Ativa)

Impede que propriedades opcionais recebam `undefined` explicitamente se não estiverem no contrato.

- **Implicação na Integridade dos Dados:** Existe uma diferença sutil entre uma propriedade que "não existe" e uma propriedade que "existe, mas seu valor é indefinido". Esta opção mantém essa distinção clara. Se um objeto tem `{ nome?: string }`, você pode passar `{}` ou `{ nome: "Gabriel" }`, mas não pode passar `{ nome: undefined }`.
- **Segurança na Comunicação com o Rust:** Isso é crucial ao enviar dados para o backend em Rust (via JSON). Muitos serializadores em Rust (como o Serde) tratam a ausência de uma chave de forma diferente de uma chave presente com valor nulo. Ao forçar essa precisão no TypeScript, você evita inconsistências onde o backend esperava que um campo nem estivesse presente, mas o frontend enviou a chave com `undefined`.

### **Style Options**

##### 13. noImplicitReturns: true (Ativado)

Garante que todas as ramificações de uma função retornem um valor.

- **Implicação de Segurança:** Evita o erro silencioso onde uma função termina sem retornar nada (retornando `undefined` por padrão) em certos caminhos lógicos (como dentro de um `if/else`). Se o seu backend Rust espera um resultado específico para processar uma lógica, um retorno implícito `undefined` no frontend pode quebrar a aplicação.
- **Manutenção:** Obriga o desenvolvedor a ser explícito. Se a função diz que retorna um número, o TypeScript garantirá que todos os caminhos possíveis entreguem um número.

##### 14. noImplicitOverride: true (Ativado)

Exige o modificador `override` ao sobrescrever métodos de classes pai.

- **Implicação na Evolução do Código:** Protege contra alterações acidentais na classe pai. Se você renomear um método na classe base em Rust (ou no seu espelho em TS), o TypeScript avisará que o método na classe filha não está mais sobrescrevendo nada, evitando que o comportamento antigo permaneça ativo por erro de digitação.

##### 15. noUnusedLocals: true (Ativado)

Reporta erro para variáveis locais que não são utilizadas.

- **Implicação de Performance e Limpeza:** Variáveis não utilizadas ocupam memória e poluem o raciocínio de quem lê o código. Em sistemas de alto desempenho (como o que você busca ao usar Rust), manter o frontend enxuto e sem "lixo" de processamento é uma boa prática de higiene digital.

##### 16. noUnusedParameters: true (Ativado)

Similar ao anterior, mas focado em parâmetros de funções.

- **Segurança de API:** Se você recebe um dado do seu servidor Rust em uma função, mas não o utiliza, isso pode indicar um erro de lógica ou uma funcionalidade esquecida. Ativar isso força você a limpar assinaturas de funções obsoletas.

##### 17. noFallthroughCasesInSwitch: true (Ativado)

Evita que um caso de um `switch` passe para o próximo sem um `break`.

- **Implicação de Erro Lógico:** É um dos bugs mais difíceis de rastrear. Sem isso, se você esquecer um `break`, o código executa o próximo bloco acidentalmente. Em sistemas de permissões ou estados (comuns em monolitos), isso pode levar a falhas de segurança onde um usuário executa uma ação de outra categoria.

##### 18. noPropertyAccessFromIndexSignature: true (Ativado)

Obriga o uso de colchetes para acessar campos definidos via assinatura de índice.

- **Precisão Semântica:** Ajuda a diferenciar campos fixos do objeto de campos dinâmicos. Se você acessa `usuario.nome`, você espera que `nome` exista. Se você acessa `usuario['campo_dinamico']`, você sinaliza que está lidando com dados que podem variar (como um dicionário de configurações vindo do banco de dados). Isso torna o código mais previsível e menos propenso a erros de digitação em propriedades dinâmicas.

### **Recommended Options**

##### 19. strict: true (Ativa)

Ativa o conjunto principal de verificações rigorosas do TypeScript.

- **Implicação de Segurança:** É a configuração de segurança mais crítica. Ela habilita automaticamente regras como `noImplicitAny` e `strictNullChecks`. Isso garante que o TypeScript te proteja contra o uso acidental de valores `null` ou `undefined` e obriga a tipagem correta, aproximando o rigor do seu Frontend ao do seu Backend em Rust.

##### 20. jsx: "react-jsx" (Removida)

Define como o JSX é transformado, otimizando para versões modernas do React.

- **Implicação no Desenvolvimento:** Permite usar arquivos `.tsx` sem a necessidade de importar o React manualmente em cada arquivo.
- **Performance:** Gera um código JavaScript compilado mais enxuto e eficiente, utilizando as APIs de transformação introduzidas nas versões mais recentes do ecossistema React.

##### 21. verbatimModuleSyntax: true (Ativa)

Mantém a sintaxe de módulos exatamente como escrita, removendo apenas os tipos.

- **Previsibilidade:** Impede que o TypeScript faça transformações "mágicas" nos seus `imports`. Isso garante que o que você escreve no código fonte seja o que chega no navegador, evitando erros onde o código tenta importar em tempo de execução algo que era apenas um Tipo.
- **Modernidade:** É essencial para garantir compatibilidade total com módulos ESM nativos, que é o padrão de projetos modernos.

##### 22. isolatedModules: true (Ativa)

Garante que cada arquivo possa ser compilado de forma independente.

- **Necessidade Técnica:** Ferramentas de build ultra-rápidas (como Vite ou esbuild) transpilam um arquivo por vez. Esta opção garante que você não use funcionalidades do TS que dependem do entendimento de todo o projeto para funcionar, evitando que seu código quebre após passar pelo processo de build.

##### 23. noUncheckedSideEffectImports: true (Ativa)

Verifica se imports de efeito colateral (como CSS) apontam para arquivos existentes.

- **Prevenção de Erros de Runtime:** Garante que se você fizer um `import "./style.css"`, o TypeScript verifique se esse arquivo realmente existe no disco. Isso evita que o frontend quebre silenciosamente no navegador por falta de um recurso visual ou script de inicialização.

##### 24. moduleDetection: "force" (Ativa)

Trata todos os arquivos como módulos independentes.

- **Isolamento de Escopo:** Garante que cada arquivo `.ts` tenha seu próprio escopo privado. Isso impede que variáveis de um arquivo "vazem" para outro de forma global, o que é fundamental para a segurança e organização de um monolito, evitando colisões de nomes de funções e variáveis.

##### 25. skipLibCheck: true (Ativa)

Pula a verificação de tipos dentro da pasta `node_modules`.

- **Performance de Build:** Bibliotecas externas podem ter definições de tipo complexas ou até imprecisas. Ao ignorar essa checagem, você acelera drasticamente o tempo de compilação, focando o poder do TypeScript apenas no código que **você** está escrevendo dentro da pasta `./src`.

##### 26. forceConsistentCasingInFileNames: true (Ativa)

Garante que o TypeScript respeite a diferenciação entre maiúsculas e minúsculas nos nomes dos arquivos.

- **Prevenção de Erros em Deploy:** O Windows ignora se você importar `Usuario.ts` como `usuario.ts`, mas o Linux (onde seu servidor Rust provavelmente rodará) não. Ativar isso evita que o projeto funcione na sua máquina e quebre misteriosamente no pipeline de deploy por um arquivo não encontrado.
- **Consistência:** Mantém o projeto organizado e previsível, seguindo o padrão de nomenclatura que você estabeleceu para o sistema.

##### 27. noEmitOnError: true (Ativa)

Impede a geração de arquivos JavaScript se houver qualquer erro de compilação no TypeScript.

- **Integridade da Build:** Garante que você nunca execute ou envie para o navegador um código que o compilador já marcou como defeituoso. Se a pasta `./dist` for gerada, você tem a certeza matemática de que aquele código passou em todos os testes de tipo.
- **Segurança de Fluxo:** Em um monolito integrado com Rust, isso evita que comportamentos inconsistentes cheguem ao ambiente de execução, forçando o desenvolvedor a corrigir a tipagem antes de testar a funcionalidade.

##### 28. moduleResolution: "Bundler" (Ativa)

Define a estratégia que o compilador usa para localizar módulos importados, otimizada para ferramentas modernas.

- **Conformidade com Ferramentas Modernas:** Se você usa Vite, Esbuild ou Webpack, esta opção alinha o TypeScript ao comportamento dessas ferramentas. Ela permite o uso de resoluções mais flexíveis e modernas (como as definidas no campo `exports` do `package.json`).
- **Facilidade no Frontend:** Evita a obrigação de incluir extensões de arquivo (como `.js`) em todos os seus `imports`, tornando a escrita do código mais natural e compatível com o ecossistema de bibliotecas atuais.

##### 29. lib: ["DOM", "DOM.Iterable", "ES2024"] (Ativa)

Especifica quais APIs nativas globais o TypeScript deve reconhecer como disponíveis.

- **Controle de Ambiente:** Ao declarar explicitamente `DOM` e `DOM.Iterable`, você habilita o suporte total para manipular o navegador (`document`, `window`, eventos). A inclusão de `ES2024` garante que você possa usar as funcionalidades mais seguras e modernas da linguagem.
- **Segurança contra APIs Obsoletas:** Limitar as bibliotecas de ambiente impede que você utilize acidentalmente funções antigas ou inseguras que o TypeScript poderia sugerir se estivesse usando configurações padrão mais genéricas.

##### 30. composite: true (Inativa)

Esta opção habilita o modo de "Projetos Referenciados" do TypeScript, permitindo que um projeto seja dividido em subprojetos menores que dependem uns dos outros.

- **O que ela faz:** Quando ativa, ela obriga o uso das opções `declaration` e `incremental`. Ela permite que o TypeScript compile partes do projeto separadamente e "reutilize" essas compilações, o que acelera o tempo de build em projetos gigantescos com centenas de arquivos.
- **Quando deve estar ativa:** Apenas se você decidir quebrar seu monolito em pacotes distintos (ex: uma pasta `core`, uma pasta `ui` e uma pasta `utils`, cada uma com seu próprio `tsconfig.json`). É o que chamamos de **Monorepo**.
- **Por que deixar inativa por enquanto:** Em um projeto Vanilla TS padrão, ela adiciona uma complexidade desnecessária. Você teria que gerenciar múltiplos arquivos de configuração e garantir que todas as referências estejam conectadas. Como você está usando o **Vite**, ele já cuida da velocidade de desenvolvimento de forma muito mais eficiente usando o Esbuild, tornando o ganho do modo `composite` quase imperceptível para projetos de tamanho médio.
- **Se estiver ativa por erro:** O TypeScript exigirá que todos os arquivos do projeto façam parte de uma estrutura de referências explícita, o que pode gerar erros chatos de "file is not under rootDir" ou "project must be referenced".

### **Configuração de Path Aliases (Ativa)**

Esta configuração permite substituir caminhos de importação longos e relativos (ex: `../../../utils/file`) por apelidos curtos e semânticos (ex: `@/utils/file`).

##### 1. Configuração no `tsconfig.json`

Nas versões modernas do TypeScript (4.1+), não é mais necessário utilizar o `baseUrl`. Você pode definir os mapeamentos diretamente no objeto `paths` de forma relativa à raiz do projeto.

- **Vantagem:** Facilita a refatoração. Se você mover um arquivo de pasta, não precisará atualizar dezenas de `../` nos imports, apenas garantir que o alias continue apontando para o local correto.
- **Segurança e Organização:** Torna a estrutura do seu monolito explícita. O prefixo `@/` sinaliza imediatamente que o arquivo pertence ao código-fonte interno do projeto.

##### 2. Sincronização com o Vite (`vite.config.ts`)

Como o TypeScript apenas cuida da verificação de tipos, o **Vite** precisa ser informado sobre como resolver esses apelidos para gerar o bundle final.

```typescript
import { defineConfig } from "vite";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

- **Importante:** Para que o código acima funcione, certifique-se de ter instalado as definições de tipo do Node com `npm install -D @types/node`, permitindo que o Vite utilize o módulo `path` para localizar os diretórios no seu sistema de arquivos.

##### 3. Impacto no Futuro (Monorepo)

O uso de aliases é um dos maiores facilitadores para migrar para um monorepo. Se amanhã você extrair sua pasta `./src/services` para um pacote independente, bastará atualizar o alias `@/services` para apontar para o novo local, sem precisar tocar em cada arquivo que realiza a importação.

### **Configuração do Vite (`vite.config.ts`)**

Este arquivo é o cérebro do seu ambiente de desenvolvimento e build. Ele conecta as regras do TypeScript com a entrega final no navegador.

```typescript
import { defineConfig } from "vite";
import path from "path";

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
```

### **Ajuste de Escopo no `tsconfig.json`**

Para evitar que arquivos de configuração (como o do Vite) interfiram na compilação do seu código-fonte, utilize a opção `exclude`.

- **O que isso faz:** Diz ao compilador: "Ignore estes arquivos/pastas quando estiver gerando o código final". O Vite continuará usando o `vite.config.ts` normalmente, mas o TypeScript não tentará mais tratá-lo como parte do seu sistema Vanilla TS.
- **Segurança:** Isso garante que o código de infraestrutura (ferramentas de build) não se misture com a lógica de negócio do seu monolito.

### **Detecção de Dependências Circulares**

Dependências circulares ocorrem quando o Arquivo A importa o B, e o Arquivo B (direta ou indiretamente) importa o A. Isso cria um acoplamento perigoso que dificulta testes e impossibilita a migração para um Monorepo.

##### 1. Instalação e Script

Embora o TypeScript permita ciclos, usamos a biblioteca `madge` para proibi-los no nosso fluxo de trabalho.

```bash
npm install -D madge
```

No `package.json`, adicione o script de verificação:

```json
"scripts": {
  "check:circular": "madge --circular --extensions ts ./src"
}
```

- **Por que uma biblioteca externa?** O compilador do TypeScript (`tsc`) ignora ciclos por design. Criar um verificador manual exigiria criar um analisador de AST (Abstract Syntax Tree) para rastrear imports recursivos. A `madge` resolve isso de forma binária: ou o código está limpo, ou ela aponta exatamente onde o ciclo começa e termina.

##### 2. Integração com Git Hooks (Husky)

Para garantir que nenhum ciclo entre no seu repositório, você pode automatizar a verificação no momento do `commit`.

1. Instale o Husky: `npm install -D husky && npx husky install`
2. Adicione o hook:

```bash
npx husky add .husky/pre-commit "npm run check:circular"
```

- **Segurança de Arquitetura:** Com esse hook, se você acidentalmente criar um ciclo durante uma refatoração, o Git impedirá o commit. Isso mantém a "saúde" do seu monolito Vanilla TS sempre pronta para uma futura expansão para Monorepo.
