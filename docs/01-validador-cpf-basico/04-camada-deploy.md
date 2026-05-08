# 🐳 Camada 4: Deploy Ultra-Minimalista

**Objetivo:** Imagem Docker "Zero-OS" e deploy em VPS.

---

## 📋 Decisões Técnicas desta Camada

### FROM scratch vs Alpine/Distroless

**Decisão:** `FROM scratch` (imagem vazia).

**Justificativa:**

- Binário estático MUSL não precisa de libs do sistema
- Imagem final: ~2-3MB (vs ~20MB Alpine, ~40MB Distroless)
- Zero superfície de ataque (sem shell, sem pacotes)
- Máxima portabilidade

**Soluções ignoradas:**

- **Alpine:** +15MB, inclui shell e libs desnecessárias
- **Distroless:** +35MB, inclui runtime de linguagem não usado
- **Ubuntu/Debian:** +100MB, absurdamente grande para binário estático

**Trade-off:** Debugabilidade vs segurança (escolhemos segurança)

- **Custo:** Sem shell para debug (`docker exec` não funciona)
- **Mitigação obrigatória:**
  - ✅ **Logs estruturados em JSON** para stdout (ver [05-otimizacoes-avancadas.md](05-otimizacoes-avancadas.md#55-observabilidade-para-produção))
  - ✅ **Endpoint `/health`** com informações do sistema
  - ✅ **Endpoint `/metrics`** para monitoramento externo (Prometheus)
  - ✅ **Debug local completo** antes de containerizar
  - 📖 **Leitura recomendada:** [`../security/observabilidade-producao.md`](../security/observabilidade-producao.md) — Guia completo de observabilidade em containers minimalistas

> **IMPORTANTE:** `FROM scratch` sem observabilidade é profissional. `FROM scratch` *com* observabilidade impecável é **engenharia de elite**.

### Kubernetes vs Docker Simples em VPS

**Decisão:** Docker standalone em VPS de 512MB.

**Justificativa:**

- MVP não precisa de orquestração
- 1 instância suficiente para carga esperada
- Custo: $5/mês vs $50/mês (cluster mínimo)
- Complexidade desnecessária para início

**Soluções ignoradas:**

- **Kubernetes:** Overhead de ~1GB RAM, complexidade de configuração
- **Docker Swarm:** Mais simples, mas ainda overhead desnecessário
- **Nomad:** Alternativa leve, mas adiciona moving parts

**Quando mudar:**

- Se precisar multi-region
- Se precisar auto-scaling horizontal
- Se tráfego justificar (>100k req/dia)

### Reverse Proxy: Caddy vs Nginx vs Traefik

**Decisão (opcional):** Caddy para HTTPS automático.

**Justificativa:**

- HTTPS automático via Let's Encrypt (zero config)
- Configuração de 3 linhas
- ~10MB de RAM
- Perfect SSL Labs score out-of-the-box

**Soluções comparadas:**

- **Nginx:** Requer configuração manual de SSL, certbot separado
- **Traefik:** Overkill, focado em Docker/K8s
- **HAProxy:** Sem auto-SSL, requer configuração complexa

**Alternativa:** Expor direto na porta 80/443

- **Viável:** Para MVP sem HTTPS
- **Não recomendado:** Navegadores marcam como inseguro

### CI/CD: GitHub Actions vs GitLab CI vs Manual

**Decisão inicial:** Deploy manual.

**Justificativa:**

- MVP em iteração rápida
- 1 desenvolvedor, poucos deploys
- Evita configuração prematura de pipelines

**Próximo passo:** GitHub Actions quando estabilizar

- **Trigger:** Push na branch `main`
- **Steps:** Build → Test → Push Docker Registry → Deploy VPS via SSH

---

## 4.1 Compilação Estática

### Passo 27: Instalar Target MUSL

- [ ] Adicionar target: `rustup target add x86_64-unknown-linux-musl`
- [ ] Instalar linker (se no Linux): `apt install musl-tools`
- [ ] No Windows: usar Docker para build (ou WSL2)

### Passo 28: Build Estático

- [ ] Compilar: `cargo build --release --target x86_64-unknown-linux-musl`
- [ ] Verificar tamanho: `ls -lh target/x86_64-unknown-linux-musl/release/identity-api`
- [ ] Validar que é estático: `ldd target/.../identity-api` (deve dizer "not a dynamic executable")

### Passo 29: Strip do Binário

- [ ] Rodar: `strip target/x86_64-unknown-linux-musl/release/identity-api`
- [ ] Comparar tamanho antes/depois
- [ ] Resultado esperado: redução de 50-70% do tamanho

---

## 4.2 Docker "FROM scratch"

### Passo 30: Criar Dockerfile Multi-Stage

- [ ] Criar `Dockerfile` na raiz do projeto:

  ```dockerfile
  # Stage 1: Build Frontend
  FROM node:20-alpine AS frontend
  WORKDIR /app
  COPY apps/identity-web/package*.json ./
  RUN npm ci
  COPY apps/identity-web/ ./
  RUN npm run build

  # Stage 2: Build Backend
  FROM rust:1.83-alpine AS builder
  RUN apk add --no-cache musl-dev
  WORKDIR /app
  COPY Cargo.toml Cargo.lock ./
  COPY services/ services/
  COPY libs/ libs/
  COPY --from=frontend /app/dist apps/identity-web/dist/
  RUN cargo build --release --target x86_64-unknown-linux-musl
  RUN strip target/x86_64-unknown-linux-musl/release/identity-api

  # Stage 3: Runtime
  FROM scratch
  # CRÍTICO: Adicionar usuário não-root
  COPY --from=builder /etc/passwd /etc/passwd
  COPY --from=builder /etc/group /etc/group
  USER 65534:65534

  COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/identity-api /app

  # CRÍTICO: Usar variável de ambiente para porta
  ENV PORT=8080
  EXPOSE 8080

  # CRÍTICO: Adicionar healthcheck
  HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app", "--health"] || exit 1

  ENTRYPOINT ["/app"]
  ```

- [ ] **NOTA:** O healthcheck requer implementar flag `--health` no backend (Passo adicional)

### Passo 31: Build da Imagem

- [ ] Criar `.dockerignore`: adicionar `target/`, `node_modules/`, `.git/`
- [ ] Build: `docker build -t cpf-validator:latest .`
- [ ] Verificar tamanho: `docker images cpf-validator` (esperado: 2-5MB)

### Passo 32: Teste Local da Imagem

- [ ] Rodar: `docker run -p 8080:8080 cpf-validator:latest`
- [ ] Testar no navegador: `http://localhost:8080`
- [ ] Validar que tudo funciona dentro do container
- [ ] Testar healthcheck: `curl http://localhost:8080/health`

---

## 4.3 Deploy em VPS

### Passo 33: Preparar VPS

- [ ] Escolher provedor (DigitalOcean, Hetzner, etc.)
- [ ] Criar VM Ubuntu 24.04 (512MB RAM suficiente!)
- [ ] SSH: `ssh root@IP_DA_VPS`
- [ ] Instalar Docker: `curl -fsSL https://get.docker.com | sh`

### Passo 34: Transferir Imagem

- [ ] **Opção A - Build na VPS:**
  - `git clone <seu-repo>`
  - `docker build -t cpf-validator .`
- [ ] **Opção B - Registry:**
  - Local: `docker tag cpf-validator seu-usuario/cpf-validator`
  - Local: `docker push seu-usuario/cpf-validator`
  - VPS: `docker pull seu-usuario/cpf-validator`

### Passo 35: Rodar em Produção

- [ ] **CRÍTICO:** Usar variáveis de ambiente:
  ```bash
  docker run -d \
    -p 80:8080 \
    -e PORT=8080 \
    -e RUST_LOG=info \
    --name cpf-api \
    --restart unless-stopped \
    --memory="128m" \
    --cpus="0.5" \
    --read-only \
    --security-opt=no-new-privileges:true \
    --cap-drop=ALL \
    cpf-validator
  ```
- [ ] Configurar firewall: `ufw allow 80/tcp && ufw enable`
- [ ] Testar: `curl http://IP_DA_VPS/health`
- [ ] Abrir no navegador: `http://IP_DA_VPS`
- [ ] **CRÍTICO:** Validar limites de recursos: `docker stats cpf-api`

### Passo 36: Monitoramento Básico

- [ ] Ver logs: `docker logs -f cpf-api`
- [ ] Verificar uso de recursos: `docker stats cpf-api`
- [ ] Testar restart: `docker restart cpf-api`
- [ ] Validar comportamento após reboot da VPS
- [ ] **CRÍTICO:** Monitorar file descriptors:

  ```bash
  # Ver file descriptors abertos
  lsof -p $(docker inspect -f '{{.State.Pid}}' cpf-api) | wc -l

  # Se crescer continuamente = vazamento de conexões
  ```

- [ ] **CRÍTICO:** Configurar log rotation:
  ```bash
  # /etc/docker/daemon.json
  {
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "10m",
      "max-file": "3"
    }
  }
  ```

---

## 4.4 HTTPS (Opcional)

### Passo 37: Configurar Caddy

- [ ] Instalar Caddy: `apt install caddy`
- [ ] Criar `Caddyfile`:
  ```
  seu-dominio.com {
      reverse_proxy localhost:8080
  }
  ```
- [ ] Recarregar: `systemctl reload caddy`
- [ ] HTTPS automático via Let's Encrypt

---

**Anterior:** [03-camada-frontend.md](03-camada-frontend.md)
**Próximo:** [99-decisoes-metricas.md](99-decisoes-metricas.md)
