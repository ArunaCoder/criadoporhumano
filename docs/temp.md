Recebi sua análise e entendo seu ponto sobre a proporcionalidade. No entanto, achei a resposta excessivamente genérica. **Tenho plena ciência de que você herdou um código de terceiros**, mas o que solicitei são ferramentas de mercado que garantem que, daqui para frente, o projeto tenha previsibilidade.

Se a sua preocupação é o esforço para adequar o legado, isso é contornável tecnicamente (usando flags de `ignore` ou validando apenas arquivos modificados via `lint-staged`) sem abrir mão da governança. O que é inegociável é que o código novo já nasça dentro desses padrões.

Para avançarmos ao kickoff, preciso que o Plano de Implementação confirme como esses pontos serão mensurados e onde eu poderei auditá-los:

> **Estratégia de Validação em Camadas:**
> As validações ocorrem em **dois momentos**: (1) **Pre-commit** via Husky (bloqueia localmente commits problemáticos antes do push); (2) **CI/CD** via GitHub Actions (valida o código após o push, antes do merge). Essa redundância garante que mesmo desenvolvedores que contornem hooks locais não consigam enviar código problemático para produção.

### 1. Propriedade, Infraestrutura e Inventário (Inegociável)

- **Métrica:** Todos os ativos vinculados às contas da **Contratante** e entrega de um **Inventário Técnico**.
- **Como confirmarei a mensuração:**
  - Verificarei se sou o "Owner" principal no GitHub, Railway e Cloudflare.
  - Receberei uma planilha com: Serviço, URL de acesso, E-mail proprietário vinculado, Nível de acesso (Admin/Dev) e Meio de pagamento cadastrado.

### 2. Governança e Padronização Automática

- **Métrica:** Uso de **Poetry** (Python), **EditorConfig**, **Prettier**, **ESLint** e **Husky** (pre-commit hooks).
- **Como confirmarei a mensuração:**
  - Verificarei a existência dos arquivos `pyproject.toml`, `.editorconfig`, `.prettierrc`, `.eslintrc.json` e `.husky/` na raiz do repositório.
  - No painel do Railway (Settings > Build), confirmarei que o comando de build está configurado como `poetry install` (não `pip install -r requirements.txt`).
  - Abrirei um arquivo Python ou TypeScript no editor e verificarei que a formatação automática está funcionando (identação, aspas, etc.).
  - Verificarei que o arquivo `.husky/pre-commit` existe e contém chamadas para `lint-staged` e `gitleaks`.

### 3. Travamento de Qualidade (Pre-commit + CI/CD)

- **Métrica:** **Pre-commit Hooks** (Husky + GitLeaks + Lint-staged + Commitlint) e **Branch Protection Rules** (CI).
- **Como confirmarei a mensuração:**
  - **Pre-commit (Local):** Tentarei fazer um commit que viole as regras e ele deve ser bloqueado **antes** do push:
    - Commit com mensagem fora do padrão Conventional Commits (ex: "ajuste") → rejeitado pelo **Commitlint**.
    - Commit com código mal formatado → corrigido automaticamente pelo **Prettier/Ruff** via **lint-staged**.
    - Commit com credenciais expostas (ex: `API_KEY=abc123`) → rejeitado pelo **GitLeaks**.
  - **CI/CD (Servidor):** No GitHub (Settings > Branches > `main`), confirmarei:
    - "Require status checks to pass before merging" ativado.
    - Checks obrigatórios incluem: `ruff`, `mypy`, `eslint`, `tsc --noEmit`, `pytest` e `gitleaks` (validação dupla).
  - Verificarei o histórico de Pull Requests para confirmar que todos os checks aparecem como executados e com status verde (✓).

### 4. Testes, Cobertura e Criticidade

- **Métrica:** Mínimo de **80% de cobertura** em regras de negócio e lógica de backend.
- **Como confirmarei a mensuração:**
  - Verificarei no log do GitHub Actions o relatório gerado pelo `pytest-cov` exibindo o percentual de cobertura por módulo.
  - Confirmarei que os módulos críticos (Pagamentos, Auth, Processamento Core) possuem ≥80% de cobertura.
  - Auditarei a pasta de testes (`tests/`) para validar a existência de arquivos específicos (`test_payments.py`, `test_auth.py`, etc.) e presença de testes unitários e de integração realistas (não apenas mocks vazios).

### 5. Proteção de Infraestrutura, Segurança e Continuidade

- **Métrica:** **Separação de ambientes**, **Backups Automáticos** e **CODEOWNERS**.
- **Como confirmarei a mensuração:**
  - **Isolamento:** Verei no painel do Railway dois "Projects" ou "Environments" distintos (Staging e Production), com variáveis de ambiente (`.env`) e bancos de dados totalmente separados.
  - **Backups:** Verei na aba "Backups" do banco de dados no Railway as rotinas diárias ativas com retenção configurada.
  - **CODEOWNERS:** Verificarei o arquivo `.github/CODEOWNERS` listando os responsáveis por arquivos críticos de infraestrutura (`.github/workflows`, `pyproject.toml`, `.env.example`).

### 6. Documentação e Validação Visual

- **Métrica:** **PR Templates**, **Lint de Docstrings** e **Deploy Previews**.
- **Como confirmarei a mensuração:**
  - **PR Templates:** Ao abrir um Pull Request, o GitHub deve carregar automaticamente um checklist pré-definido (`.github/pull_request_template.md`).
  - **Lint de Docstrings:** No log do GitHub Actions, verificarei a execução do `pydocstyle` ou `ruff` (com regras D\*) validando docstrings em funções públicas. Commits que violarem este padrão devem reprovar nos checks.
  - **Deploy Previews:** No final de cada Pull Request aberto, haverá um link automático gerado pelo Cloudflare (ex: `https://pr-123.saas.pages.dev`) para que eu teste a versão antes da aprovação.

### 7. Refatoração Gradual do Código Legado

- **Métrica:** **Lint-staged**, **Boy Scout Rule** e **Tracking de Débito Técnico**.
- **Como confirmarei a mensuração:**
  - **Lint-staged:** Verificarei a existência do arquivo `.lintstagedrc.json` ou configuração em `package.json` aplicando linters (ESLint, Ruff, Prettier) apenas em arquivos modificados via `git diff --staged`.
  - **Estratégia Boy Scout:** No PR Template, confirmarei a existência de um item de checklist perguntando "O código modificado está melhor do que quando foi encontrado?" (refatoração de funções grandes, adição de type hints, docstrings, etc.).
  - **Tracking:** Verificarei no GitHub Projects ou Issues a existência de uma label "tech-debt" e pelo menos um milestone "Legacy Refactor" com issues priorizadas por criticidade (Auth, Payments, Core) listando arquivos específicos que precisam ser adequados.
  - **Métricas de Progresso:** A cada sprint, receberei um relatório simples (pode ser um comentário no Issue de milestone) mostrando: Total de arquivos legados identificados, Total refatorados, Percentual de conformidade atual (ex: 15/50 arquivos = 30%).

---

### Resumo: O que roda no Pre-commit vs CI/CD?

**Pre-commit (Husky) — Validação Local Instantânea:**

- GitLeaks (detecta secrets antes do commit)
- Lint-staged (aplica ESLint, Ruff, Prettier apenas em arquivos modificados)
- Commitlint (valida formato da mensagem de commit)
- Type checking rápido (opcional, apenas em arquivos modificados)

**CI/CD (GitHub Actions) — Validação Completa no Servidor:**

- GitLeaks (validação redundante em todo o histórico)
- Linters completos (ESLint, Ruff em todos os arquivos, não apenas modificados)
- Type checking completo (mypy + tsc --noEmit em toda a codebase)
- Pytest + cobertura (testes unitários e de integração)
- Build completo (validação de compilação)
- Deploy preview (ambiente temporário para revisão visual)

**Vantagem:** Feedback instantâneo para o desenvolvedor (pre-commit) + validação completa garantida no servidor (CI).

---

Vale ressaltar que, com exceção da **escrita de testes** e da **refatoração gradual do legado** — que são os dois únicos requisitos que exigirão esforço intelectual contínuo —, todo o restante da lista é **automação pura**. Uma vez configurado, o sistema trabalhará sozinho para garantir que o código novo já nasça dentro dos padrões, sem gerar carga extra de trabalho manual para você.

Para um desenvolvedor experiente, esse setup de infraestrutura leva poucas horas. Preciso que você confirme: **conseguimos deixar essa infraestrutura de governança pronta, isolando o legado onde for necessário, para que o meu acompanhamento seja feito pelas ferramentas e não por revisões manuais?**
