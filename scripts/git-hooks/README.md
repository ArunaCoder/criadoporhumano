# Git Hooks

Este projeto usa hooks do Git versionados para manter qualidade e padrões no código.

## Configuração

Os hooks estão configurados para serem executados automaticamente a partir desta pasta:

```bash
git config core.hooksPath scripts/git-hooks
```

## Requisitos

- **Gitleaks**: Ferramenta para detectar secrets vazados no código
  - Windows: `choco install gitleaks -y`
  - Linux/macOS: `brew install gitleaks`
  - Ou baixe o binário: https://github.com/gitleaks/gitleaks/releases

## Hooks Disponíveis

### pre-commit

Executa múltiplas validações de qualidade e segurança antes de permitir o commit.

#### 1. Secrets vazados (Gitleaks)

Escaneia arquivos staged em busca de **secrets vazados** (API keys, tokens, senhas, etc.).

**O que é verificado:**

- API keys (OpenAI, AWS, Google, Stripe, Mercado Pago)
- Tokens de autenticação (Bearer, JWT, Slack)
- Chaves privadas (PEM/RSA)
- Strings de conexão de banco de dados
- Configurações sensíveis do Firebase
- Variáveis de ambiente suspeitas

**Configuração:** As regras estão definidas em [.gitleaks.toml](../../.gitleaks.toml)

**Se bloqueado:**

1. Remova o secret do código
2. Use variáveis de ambiente (.env) que não são versionadas
3. Se for falso positivo, adicione à allowlist no .gitleaks.toml

#### 2. Dependências circulares

Verifica se há imports circulares entre módulos TypeScript usando `check-cycles.mjs`.

**Por que importa:** Dependências circulares causam:

- Bugs difíceis de debugar (ordem de inicialização indefinida)
- Problemas de bundling (Vite, Webpack)
- Código difícil de testar e manter

**Se bloqueado:**

```bash
npm run check-cycles:verbose  # Ver detalhes do ciclo
```

#### 3. Tamanho de arquivos

Bloqueia commits com arquivos muito longos (>500 linhas por padrão).

**Por que importa:** Arquivos grandes são:

- Difíceis de revisar em PRs
- Violam Single Responsibility Principle
- Indicam falta de modularização

**Se bloqueado:**

- Refatore o arquivo em módulos menores
- Separe responsabilidades
- Use composição ao invés de herança

### commit-msg

Valida que as mensagens de commit seguem o padrão **Conventional Commits**.

**Formato aceito:**

```
tipo(escopo): descrição
```

**Tipos válidos:**

- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `style`: Formatação
- `refactor`: Refatoração de código
- `perf`: Melhoria de performance
- `test`: Testes
- `build`: Sistema de build
- `ci`: Integração contínua
- `chore`: Tarefas gerais
- `revert`: Reverter commits

**Exemplos válidos:**

- `feat: adiciona nova funcionalidade`
- `fix(auth): corrige validação de token`
- `docs(readme): atualiza instruções`

**Exemplos inválidos:**

- `adiciona nova feature` ❌
- `Fix bug` ❌
- `WIP` ❌

## Setup em Novo Clone

Após clonar o repositório:

1. **Instale o Gitleaks** (se ainda não tiver):

   ```bash
   # Windows com Chocolatey
   choco install gitleaks -y

   # Linux/macOS com Homebrew
   brew install gitleaks
   ```

2. **Configure o Git para usar os hooks:**
   ```bash
   git config core.hooksPath scripts/git-hooks
   ```

No Windows com Git Bash, os hooks devem funcionar automaticamente.

## Nota sobre Permissões

No Linux/macOS, pode ser necessário dar permissão de execução:

```bash
chmod +x scripts/git-hooks/*
```
