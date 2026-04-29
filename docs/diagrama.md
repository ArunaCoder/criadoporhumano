# Estrutura de Pastas e Arquivos - Criado por Humano

## Visão Geral

**Tipo:** Monorepo
**Build System:** Cargo Workspaces (Rust) + npm Workspaces (TypeScript)
**Organização Backend:** Domain-Driven (por feature)
**Organização Frontend:** Vanilla TypeScript + Vite
**Containerização:** Docker desde o início

---

## Estrutura Completa

```
criadoporhumano/
├── .github/
│   └── workflows/
│       ├── backend-ci.yml          # CI/CD para Rust
│       ├── frontend-ci.yml         # CI/CD para Frontend
│       └── deploy.yml              # Deploy automático
│
├── backend/
│   ├── Cargo.toml                  # Workspace root
│   ├── Dockerfile
│   ├── .dockerignore
│   │
│   ├── api/                        # HTTP Server (Axum/Actix)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── main.rs
│   │       ├── routes/             # Definição de rotas
│   │       │   ├── mod.rs
│   │       │   ├── auth.rs
│   │       │   ├── biometric.rs
│   │       │   └── certification.rs
│   │       ├── middleware/         # Auth, CORS, Rate limiting
│   │       └── config.rs
│   │
│   ├── auth/                       # Domínio: Autenticação
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── models/             # User, Session, Token
│   │       ├── service.rs          # Lógica de negócio
│   │       ├── repository.rs       # Queries DB
│   │       ├── jwt.rs              # JWT handling
│   │       └── two_factor.rs       # 2FA (TOTP)
│   │
│   ├── biometric/                  # Domínio: Análise Biométrica (CORE)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── models/             # BiometricData, AnalysisResult
│   │       ├── analyzer.rs         # Algoritmo principal
│   │       ├── statistics.rs       # Desvio padrão, entropia
│   │       ├── scoring.rs          # Cálculo de score 0-100%
│   │       └── baseline.rs         # Perfil biométrico do usuário
│   │
│   ├── certification/              # Domínio: Certificados
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── models/             # Certificate, Badge
│   │       ├── service.rs          # Geração de certificados
│   │       ├── repository.rs
│   │       └── verification.rs     # Validação pública
│   │
│   ├── users/                      # Domínio: Usuários
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── models/             # User, Profile, Settings
│   │       ├── service.rs
│   │       └── repository.rs
│   │
│   ├── billing/                    # Domínio: Pagamentos
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── models/             # Subscription, Invoice
│   │       ├── service.rs
│   │       ├── stripe.rs           # Integração Stripe
│   │       └── mercadopago.rs      # Integração Mercado Pago
│   │
│   ├── storage/                    # Domínio: Armazenamento Criptografado
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── encryption.rs       # AES-256
│   │       ├── kms.rs              # Key Management
│   │       └── repository.rs
│   │
│   ├── notifications/              # Domínio: Emails/Notificações
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── email.rs            # SendGrid/SES
│   │       ├── templates/          # Templates de email
│   │       └── service.rs
│   │
│   ├── shared/                     # Código compartilhado
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── db.rs               # Pool PostgreSQL
│   │       ├── redis.rs            # Cliente Redis
│   │       ├── errors.rs           # Error types customizados
│   │       ├── utils.rs
│   │       └── types.rs            # Types comuns
│   │
│   ├── cli/                        # CLI tools (migrations, admin)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── main.rs
│   │
│   ├── migrations/                 # SQL migrations
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_add_biometric_tables.sql
│   │   └── ...
│   │
│   └── tests/
│       ├── integration/            # Testes de integração
│       └── fixtures/               # Dados de teste
│
├── frontend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── Dockerfile
│   ├── .dockerignore
│   │
│   ├── public/
│   │   ├── favicon.ico
│   │   └── assets/
│   │       └── images/
│   │
│   ├── src/
│   │   ├── main.ts                 # Entry point
│   │   ├── app.ts                  # App principal
│   │   │
│   │   ├── pages/                  # Páginas da aplicação
│   │   │   ├── index.ts
│   │   │   ├── auth/
│   │   │   │   ├── login.ts
│   │   │   │   ├── register.ts
│   │   │   │   └── forgot-password.ts
│   │   │   ├── dashboard/
│   │   │   │   └── dashboard.ts
│   │   │   ├── editor/             # Editor com Lexical
│   │   │   │   ├── editor.ts
│   │   │   │   └── lexical-setup.ts
│   │   │   ├── certificates/
│   │   │   │   ├── list.ts
│   │   │   │   └── detail.ts
│   │   │   ├── settings/
│   │   │   │   └── settings.ts
│   │   │   └── verify/             # Página pública de verificação
│   │   │       └── verify.ts
│   │   │
│   │   ├── components/             # Web Components reutilizáveis
│   │   │   ├── base/
│   │   │   │   ├── button.ts
│   │   │   │   ├── input.ts
│   │   │   │   └── modal.ts
│   │   │   ├── layout/
│   │   │   │   ├── header.ts
│   │   │   │   ├── sidebar.ts
│   │   │   │   └── footer.ts
│   │   │   ├── editor/
│   │   │   │   └── biometric-toolbar.ts
│   │   │   └── certificates/
│   │   │       ├── certificate-card.ts
│   │   │       └── badge-widget.ts
│   │   │
│   │   ├── lib/                    # Bibliotecas core
│   │   │   ├── biometric/          # CORE: Captura biométrica
│   │   │   │   ├── index.ts
│   │   │   │   ├── keyboard-tracker.ts  # Dwell/Flight time
│   │   │   │   ├── mouse-tracker.ts     # Mouse tracking
│   │   │   │   ├── buffer.ts            # Batch de eventos
│   │   │   │   └── types.ts
│   │   │   ├── api/                # Client API
│   │   │   │   ├── index.ts
│   │   │   │   ├── auth.ts
│   │   │   │   ├── biometric.ts
│   │   │   │   └── certificates.ts
│   │   │   ├── auth/               # Gerenciamento JWT
│   │   │   │   └── token-manager.ts
│   │   │   └── utils/
│   │   │       ├── validators.ts
│   │   │       └── formatters.ts
│   │   │
│   │   ├── router/                 # Roteamento SPA
│   │   │   └── index.ts
│   │   │
│   │   ├── stores/                 # State management (vanilla)
│   │   │   ├── auth-store.ts
│   │   │   ├── editor-store.ts
│   │   │   └── ui-store.ts
│   │   │
│   │   ├── styles/                 # CSS
│   │   │   ├── main.css
│   │   │   ├── variables.css       # Design tokens
│   │   │   ├── components/
│   │   │   └── pages/
│   │   │
│   │   └── types/                  # TypeScript types
│   │       ├── api.ts
│   │       ├── biometric.ts
│   │       └── models.ts
│   │
│   ├── tests/
│   │   ├── unit/
│   │   └── e2e/                    # Playwright/Cypress
│   │
│   └── index.html
│
├── sdk/                            # SDK JavaScript (NPM package)
│   ├── package.json
│   ├── tsconfig.json
│   ├── rollup.config.js            # Bundler
│   │
│   ├── src/
│   │   ├── index.ts                # Export principal
│   │   ├── biometric-capture.ts   # Classe principal
│   │   ├── adapters/               # Adapters para plataformas
│   │   │   ├── base.ts
│   │   │   ├── wordpress.ts
│   │   │   └── generic.ts
│   │   └── types.ts
│   │
│   ├── examples/                   # Exemplos de uso
│   │   ├── vanilla.html
│   │   └── wordpress.php
│   │
│   └── dist/                       # Build output (gitignore)
│
├── browser-extension/              # Extensão Chrome/Firefox (v1.5+)
│   ├── package.json
│   ├── manifest.json               # Chrome extension manifest
│   │
│   ├── src/
│   │   ├── background/             # Service worker
│   │   ├── content/                # Content scripts
│   │   ├── popup/                  # Popup UI
│   │   └── shared/                 # Código compartilhado
│   │
│   └── dist/
│
├── infra/
│   ├── docker/
│   │   ├── docker-compose.yml      # Local development
│   │   ├── docker-compose.prod.yml # Production
│   │   ├── backend.Dockerfile      # Backend production
│   │   └── frontend.Dockerfile     # Frontend production
│   │
│   ├── nginx/
│   │   ├── nginx.conf              # Config principal
│   │   └── ssl/                    # Certificados SSL
│   │
│   ├── postgres/
│   │   └── init.sql                # Schema inicial
│   │
│   ├── redis/
│   │   └── redis.conf
│   │
│   ├── monitoring/                 # Grafana + Prometheus
│   │   ├── grafana/
│   │   │   └── dashboards/
│   │   └── prometheus/
│   │       └── prometheus.yml
│   │
│   └── scripts/
│       ├── backup.sh               # Backup PostgreSQL
│       ├── deploy.sh               # Script de deploy
│       └── setup-dev.sh            # Setup ambiente local
│
├── docs/
│   ├── api/
│   │   ├── openapi.yml             # OpenAPI 3.0 spec
│   │   └── postman-collection.json
│   │
│   ├── architecture/
│   │   ├── adr/                    # Architecture Decision Records
│   │   ├── diagrams/               # Draw.io, Mermaid
│   │   └── database-schema.md
│   │
│   ├── planning/
│   │   ├── geral.md                # Planejamento atual
│   │   ├── diagrama.md             # Este arquivo
│   │   └── roadmap.md
│   │
│   └── user-guides/
│       ├── getting-started.md
│       ├── api-integration.md
│       └── wordpress-plugin.md
│
├── scripts/
│   ├── setup.sh                    # Setup inicial do projeto
│   ├── test.sh                     # Roda todos os testes
│   └── build.sh                    # Build completo
│
├── .env.example                    # Template de variáveis
├── .gitignore
├── .gitattributes
├── .editorconfig
├── README.md                       # Documentação principal
├── LICENSE
├── CONTRIBUTING.md
└── CHANGELOG.md
```

---

## Explicação de Decisões Arquiteturais

### **Backend (Rust)**

**Cargo Workspace**: Permite compilação incremental e compartilhamento de dependências.

```toml
# backend/Cargo.toml
[workspace]
members = [
    "api",
    "auth",
    "biometric",
    "certification",
    "users",
    "billing",
    "storage",
    "notifications",
    "shared",
    "cli",
]
```

**Domínios isolados**: Cada `crate` é um domínio independente com:

- `models/`: Structs e tipos
- `service.rs`: Lógica de negócio
- `repository.rs`: Acesso a dados
- Dependências explícitas entre crates

---

### **Frontend (Vanilla TypeScript + Vite)**

**Estrutura por tipo**: Separação clara entre páginas, componentes, lib.

**Biometric lib**: Core de captura isolado e reutilizável (pode virar o SDK).

**Zero framework**: Web Components nativos ou classes vanilla para componentes.

---

### **SDK JavaScript**

**Standalone package**: Publicável no NPM para uso externo.

**Adapters pattern**: Permite extensão para diferentes plataformas mantendo core único.

---

### **Infra**

**Docker Compose**: Desenvolvimento local completo (backend + frontend + PostgreSQL + Redis).

**Nginx**: Reverse proxy para produção.

**Monitoring**: Stack observability desde o início.

---

## Próximos Passos

1. ✅ Estrutura definida
2. ⬜ Criar scaffolding inicial
3. ⬜ Configurar Docker local
4. ⬜ Setup CI/CD básico
5. ⬜ Implementar domínio `auth` (primeiro)
6. ⬜ Implementar domínio `biometric` (core)

---

**Quer que eu gere os arquivos de configuração iniciais (Cargo.toml, package.json, docker-compose.yml)?**
