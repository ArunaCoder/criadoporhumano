# Criado por Humano

> **Plataforma SaaS de análise biométrica para certificação de autoria humana em textos**

Sistema de detecção e certificação de autoria humana baseado em padrões biométricos de digitação e comportamento do mouse. Desenvolvido para combater a crescente dificuldade de diferenciar conteúdo genuinamente humano de conteúdo gerado por IA.

---

## 🎯 Visão Geral

**Criado por Humano** captura dados biométricos durante a escrita (dwell time, flight time, trajetória do mouse) e utiliza algoritmos estatísticos para gerar um score de confiança (0-100%) sobre a autoria humana. Textos certificados recebem um selo digital verificável publicamente.

### Casos de Uso

- **Jornalismo:** Certificação de artigos escritos por jornalistas
- **Agências de Conteúdo:** Comprovação de autoria original em entregas para clientes
- **E-commerce:** Validação de descrições de produtos escritas por humanos
- **Educação:** Verificação de trabalhos acadêmicos

---

## 🏗️ Arquitetura

### **Monorepo Híbrido**

- **Backend:** Rust (Axum/Actix-web) — performance crítica
- **Frontend:** Vanilla TypeScript + Lexical Editor
- **Banco de Dados:** PostgreSQL + Redis
- **SDK:** Biblioteca JavaScript publicável no npm
- **Browser Extension:** Chrome/Firefox para integração universal

```
criadoporhumano/
├── backend/           # Rust services (futuro)
├── frontend/          # Aplicação web principal
├── sdk/               # @criadoporhumano/sdk (npm)
├── browser-extension/ # Extensão de navegador
├── infra/            # Docker, nginx, monitoring
└── docs/             # Documentação técnica
```

---

## 🔒 Segurança e Privacidade

- **Criptografia AES-256** para textos em repouso
- **TLS 1.3** obrigatório para comunicação
- **Conformidade LGPD:** Consentimento explícito, portabilidade e direito ao esquecimento
- **Auditoria Completa:** Logs de acesso sem exposição de conteúdo
- **Zero-Knowledge:** Staff não tem acesso a textos descriptografados

---

## 🚀 Stack Tecnológica

### Backend (em desenvolvimento)

- **Rust** — Axum/Actix-web
- **PostgreSQL** — Dados estruturados
- **Redis** — Cache e análise em tempo real

### Frontend

- **TypeScript** — Vanilla (sem frameworks pesados)
- **Lexical** — Editor de texto (Meta)
- **Vite** — Build tool

### Infraestrutura

- **Docker** — Containerização
- **Nginx** — Reverse proxy
- **Grafana + Prometheus** — Observabilidade

---

## 📦 Workspaces (npm)

O projeto usa **npm workspaces** para gerenciar múltiplos pacotes:

```bash
npm install              # Instala todas as dependências
npm run dev              # Roda frontend em dev mode
npm run build            # Build de todos os workspaces
npm run lint             # Lint em todos os projetos
```

### Projetos Individuais

```bash
# Frontend
cd frontend && npm run dev

# SDK
cd sdk && npm run build

# Browser Extension
cd browser-extension && npm run build
```

---

## 🔧 Setup de Desenvolvimento

### Pré-requisitos

- **Node.js** 18+ (com npm workspaces)
- **TypeScript** 5.9+
- **Git** com hooks configurados
- **Gitleaks** (detecção de secrets)

### Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/criadoporhumano.git
cd criadoporhumano

# Instale as dependências
npm install

# Configure os hooks do Husky (automático via prepare)
# Hooks: pre-commit (gitleaks, typecheck, cycles) e commit-msg (conventional commits)

# Rode o frontend
npm run dev
```

---

## 🛡️ Git Hooks e Qualidade

### Pre-commit

- ✅ Verifica node_modules indevidos
- ✅ Roda Gitleaks (detecção de secrets)
- ✅ TypeScript typecheck em todos os workspaces
- ✅ Detecção de dependências circulares
- ✅ Validação de tamanho de arquivos

### Commit-msg

- ✅ Valida formato **Conventional Commits**
  ```
  feat(scope): descrição
  fix: correção de bug
  docs: atualização de documentação
  ```

---

## 📚 Documentação

- **[Planejamento Geral](docs/geral.md)** — Roadmap completo do produto
- **[Diagrama de Estrutura](docs/diagrama.md)** — Arquitetura detalhada
- **[Primeiro Deploy](docs/primeiro-deploy.md)** — Guia de implantação

---

## 🤝 Contribuindo

Este é um projeto privado em desenvolvimento inicial. Contribuições externas não estão abertas no momento.

### Padrões de Código

- **Idioma:** Código em inglês, documentação em português
- **TypeScript Strict Mode:** Habilitado em todos os projetos
- **Clippy:** Obrigatório para Rust (quando implementado)
- **Commits Convencionais:** Obrigatório via hook

---

## 📄 Licença

Proprietary — Todos os direitos reservados.

---

## 📧 Contato

**Website:** criadoporhumano.com.br (em breve)
**Repositório:** Privado

---

<p align="center">
  <strong>🚧 Projeto em desenvolvimento ativo 🚧</strong>
</p>
