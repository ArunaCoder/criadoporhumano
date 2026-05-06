# Primeiro Deploy Mínimo - Walking Skeleton

## Objetivo

Validar toda a stack de infraestrutura com uma aplicação "Hello World" funcional em produção, antes de implementar qualquer feature complexa.

## Por que fazer isso CEDO?

✅ **Detecta problemas de infra no início** (não 6 meses depois)
✅ **Valida SSL, domínio, DNS, firewall** desde já
✅ **Testa deploy real** antes de ter código crítico
✅ **Feedback loop rápido** - você vê seu trabalho online
✅ **Prática de CI/CD** desde o dia 1
✅ **Confiança** - sabe que consegue colocar em produção

---

## Escopo do MVP de Deploy (1-2 dias de trabalho)

### Backend Mínimo

```rust
// API Rust que responde:
GET /health → { "status": "ok", "version": "0.1.0" }
GET /      → "Criado por Humano API"
```

### Frontend Mínimo

```html
<!-- Página HTML estática que mostra: -->
- Logo/título "Criado por Humano" - Mensagem "Em construção" - Status do backend
(chamada ao /health)
```

### Infraestrutura

- ✅ VPS configurado
- ✅ Domínio apontando
- ✅ SSL/HTTPS funcionando
- ✅ Docker rodando
- ✅ Nginx como reverse proxy
- ✅ Deploy manual (automático vem depois)

---

## Checklist de Tarefas

### Fase 1: Preparação Local (30min)

- [ ] **Backend Hello World**

  ```bash
  # backend/api/src/main.rs
  cargo new --bin backend
  # Implementar endpoint /health básico com Axum
  cargo build --release
  ```

- [ ] **Frontend Hello World**

  ```bash
  # frontend/
  npm create vite@latest
  # Criar index.html simples
  npm run build
  ```

- [ ] **Dockerfile Backend**

  ```dockerfile
  FROM rust:1.75 as builder
  WORKDIR /app
  COPY . .
  RUN cargo build --release

  FROM debian:bookworm-slim
  COPY --from=builder /app/target/release/api /usr/local/bin/
  CMD ["api"]
  ```

- [ ] **Dockerfile Frontend**
  ```dockerfile
  FROM nginx:alpine
  COPY dist/ /usr/share/nginx/html/
  COPY nginx.conf /etc/nginx/conf.d/default.conf
  ```

---

### Fase 2: Setup VPS (1-2h)

#### 2.1 Acesso e Segurança

```bash
# SSH na VPS Hostinger
ssh root@SEU_IP

# Criar usuário não-root
adduser deploy
usermod -aG sudo deploy
usermod -aG docker deploy

# Configurar SSH key (na sua máquina local)
ssh-copy-id deploy@SEU_IP

# Desabilitar login root (segurança)
sudo nano /etc/ssh/sshd_config
# Mudar: PermitRootLogin no
sudo systemctl restart sshd
```

#### 2.2 Instalar Docker

```bash
# Instalar Docker + Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo apt update
sudo apt install docker-compose-plugin
```

#### 2.3 Firewall

```bash
# Configurar UFW
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
```

---

### Fase 3: Domínio e SSL (30min-1h)

#### 3.1 Configurar DNS

```
No painel da Hostinger ou Registro.br:

Tipo  | Nome | Valor
------|------|------
A     | @    | SEU_IP_VPS
A     | www  | SEU_IP_VPS
A     | api  | SEU_IP_VPS

Aguardar propagação: 5min-2h
```

#### 3.2 Instalar Certbot (SSL gratuito)

```bash
# Instalar Certbot
sudo apt install certbot python-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d criadoporhumano.com.br -d www.criadoporhumano.com.br -d api.criadoporhumano.com.br

# Testar renovação automática
sudo certbot renew --dry-run
```

---

### Fase 4: Deploy da Aplicação (1h)

#### 4.1 Estrutura no Servidor

```bash
# Criar estrutura
ssh deploy@SEU_IP
mkdir -p ~/criadoporhumano/{backend,frontend,infra}
cd ~/criadoporhumano
```

#### 4.2 Enviar Código

```bash
# Na sua máquina local
# Opção 1: rsync (simples)
rsync -avz --exclude 'target' --exclude 'node_modules' \
  ./backend deploy@SEU_IP:~/criadoporhumano/

rsync -avz --exclude 'node_modules' \
  ./frontend deploy@SEU_IP:~/criadoporhumano/

# Opção 2: Git (melhor)
git push origin main
# No servidor: git clone seu-repo
```

#### 4.3 Docker Compose Simples

```yaml
# infra/docker/docker-compose.prod.yml
version: "3.8"

services:
  backend:
    build: ../../backend
    container_name: criadoporhumano-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - RUST_LOG=info
    networks:
      - app-network

  frontend:
    build: ../../frontend
    container_name: criadoporhumano-web
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt:ro
    networks:
      - app-network
    depends_on:
      - backend

networks:
  app-network:
    driver: bridge
```

#### 4.4 Nginx Config para Frontend

```nginx
# frontend/nginx.conf
server {
    listen 80;
    server_name criadoporhumano.com.br www.criadoporhumano.com.br;

    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }

    # Proxy para backend
    location /api/ {
        proxy_pass http://backend:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /health {
        proxy_pass http://backend:3000/health;
    }
}
```

#### 4.5 Build e Start

```bash
# No servidor
cd ~/criadoporhumano/infra/docker
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d

# Verificar logs
docker compose logs -f

# Testar
curl http://localhost:3000/health
curl http://localhost/
```

---

### Fase 5: Validação (15min)

#### Checklist de Testes

```bash
# 1. Backend está respondendo?
curl https://api.criadoporhumano.com.br/health
# Esperado: {"status":"ok","version":"0.1.0"}

# 2. Frontend carrega?
curl https://criadoporhumano.com.br
# Esperado: HTML com "Em construção"

# 3. HTTPS funciona?
curl -I https://criadoporhumano.com.br | grep "HTTP/2 200"
# Esperado: HTTP/2 200

# 4. Redirecionamento HTTP → HTTPS?
curl -I http://criadoporhumano.com.br | grep "301"
# Esperado: 301 Moved Permanently

# 5. Containers rodando?
docker ps
# Esperado: 2 containers UP
```

#### Validação no Browser

1. Abrir `https://criadoporhumano.com.br`
   - ✅ Página carrega
   - ✅ SSL válido (cadeado verde)
   - ✅ Mostra "Em construção"

2. Abrir `https://api.criadoporhumano.com.br/health`
   - ✅ JSON retorna `{"status":"ok"}`

3. Console do navegador (F12)
   - ✅ Sem erros CORS
   - ✅ Request para `/api/health` funciona

---

## Script de Deploy Rápido (para próximas vezes)

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

echo "🚀 Deploying to production..."

# Build local
echo "📦 Building..."
cd backend && cargo build --release
cd ../frontend && npm run build

# Upload
echo "📤 Uploading..."
rsync -avz --delete ./backend/target/release/api deploy@$VPS_IP:~/app/
rsync -avz --delete ./frontend/dist/ deploy@$VPS_IP:~/app/frontend/

# Restart
echo "🔄 Restarting containers..."
ssh deploy@$VPS_IP "cd ~/criadoporhumano/infra/docker && docker compose restart"

echo "✅ Deploy complete!"
echo "🌐 https://criadoporhumano.com.br"
```

---

## Troubleshooting Comum

### Problema: Porta 80/443 já em uso

```bash
# Parar serviço Apache/Nginx padrão
sudo systemctl stop apache2
sudo systemctl disable apache2
```

### Problema: Docker não encontra imagens

```bash
# Rebuild forçado
docker compose build --no-cache
```

### Problema: SSL não funciona

```bash
# Verificar logs do Certbot
sudo certbot certificates
# Re-obter certificado
sudo certbot --nginx --force-renewal
```

### Problema: CORS errors

```nginx
# Adicionar no nginx.conf
add_header Access-Control-Allow-Origin *;
add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
```

---

## Custo Total

**Tempo:** ~4-6 horas (primeira vez)
**Dinheiro:** R$ 0 (apenas o custo do VPS que já existe)

---

## Próximos Passos (DEPOIS do Walking Skeleton)

1. ✅ Walking Skeleton funcionando
2. ⬜ Adicionar PostgreSQL ao docker-compose
3. ⬜ Adicionar Redis
4. ⬜ Implementar endpoint de auth real
5. ⬜ Setup CI/CD (GitHub Actions)
6. ⬜ Monitoramento básico

---

## Resultado Final

Ao completar este deploy, você terá:

✅ **URL pública funcionando** com SSL
✅ **Backend Rust** rodando em produção
✅ **Frontend** servido via Nginx
✅ **Confiança** de que a stack funciona
✅ **Base sólida** para adicionar features

**Tempo para adicionar features:** Reduzido em 80%
**Risco de surpresas no final:** Eliminado

---

**Este é o momento certo de fazer isso: ANTES de escrever código complexo!** 🎯
