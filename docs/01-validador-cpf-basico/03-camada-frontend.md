# 🎨 Camada 3: Frontend & Assets Embutidos

**Objetivo:** Single-binary distribution sem crates de terceiros.

---

## 📋 Decisões Técnicas desta Camada

### Vanilla TypeScript vs React/Vue/Svelte

**Decisão:** Vanilla TS sem framework frontend.

**Justificativa:**

- Interface é trivial: 1 input + 1 botão + 1 div de resultado
- Zero build complexity adicional
- Bundle final: <5KB (vs ~50KB+ com frameworks)
- Controle total sobre DOM e eventos
- Performance nativa do navegador

**Soluções ignoradas:**

- **React:** +45KB minificado, overkill para formulário simples
- **Vue:** +35KB, Virtual DOM desnecessário
- **Svelte:** Menor (~10KB), mas adiciona step de compilação complexo
- **Alpine.js:** +15KB, ainda é framework

**Trade-off:** Produtividade vs tamanho do bundle (escolhemos tamanho)

### Assets Embutidos vs Servir de Disco

**Decisão:** Embedar com `include_str!` no binário.

**Justificativa:**

- Single binary distribution (objetivo do projeto)
- Simplicidade de deploy (1 arquivo)
- Sem necessidade de gerenciar paths relativos
- Assets são pequenos (<50KB total)
- Sem risco de arquivos faltando em produção

**Solução ignorada:** Servir de `./public/` ou `./static/`

- **Problema:** Requer gerenciar paths, criar diretórios, copiar arquivos
- **Problema:** Binário não é auto-suficiente
- **Quando usar:** Se assets forem >10MB ou precisarem hot-reload

### CSS Framework vs Vanilla CSS

**Decisão:** CSS puro, sem frameworks.

**Justificativa:**

- Apenas 1 página, ~50 linhas de CSS
- Tailwind/Bootstrap adicionam 50-200KB
- Controle total sobre estilos
- Zero dependências npm adicionais

**Soluções ignoradas:**

- **Tailwind CSS:** +50KB, classes utilitárias desnecessárias para 1 formulário
- **Bootstrap:** +150KB, componentes não utilizados
- **Trade-off:** Velocidade de desenvolvimento vs tamanho (escolhemos tamanho)

---

## 3.1 Criar Frontend Básico

### Passo 20: Estrutura HTML

- [ ] Criar `apps/identity-web/src/index.html`
- [ ] Implementar formulário:
  - Input text com id `cpf-input` e placeholder `000.000.000-00`
  - Botão "Validar" com id `validate-btn`
  - Div para resultado com id `result`
- [ ] Incluir `<script src="/static/main.js"></script>` no final

### Passo 21: Vanilla JavaScript/TypeScript

- [ ] Criar `apps/identity-web/src/main.ts`
- [ ] Implementar máscara de CPF em tempo real (listener no input):
  ```typescript
  function formatCPF(value: string): string {
    const nums = value.replace(/\D/g, "").slice(0, 11);
    return nums.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4");
  }
  ```
- [ ] **CRÍTICO:** Adicionar validação client-side antes de enviar:
  ```typescript
  function isValidCPFFormat(cpf: string): boolean {
    const nums = cpf.replace(/\D/g, "");
    return nums.length === 11 && /^\d+$/.test(nums);
  }
  ```
- [ ] **CRÍTICO:** Implementar função de validação com timeout e loading state:

  ```typescript
  async function validateCPF(cpf: string) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

    try {
      const res = await fetch("/api/validate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ cpf }),
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (err) {
      clearTimeout(timeoutId);
      if (err.name === "AbortError") throw new Error("Timeout");
      throw err;
    }
  }
  ```

- [ ] **CRÍTICO:** Adicionar UI de loading state:
  ```typescript
  button.addEventListener("click", async () => {
    button.disabled = true;
    button.textContent = "Validando...";
    try {
      const result = await validateCPF(cpfInput.value);
      showResult(result);
    } catch (err) {
      showError(err.message);
    } finally {
      button.disabled = false;
      button.textContent = "Validar";
    }
  });
  ```
- [ ] Event listener no botão para chamar API e mostrar resultado

### Passo 22: CSS Minimalista

- [ ] Criar `apps/identity-web/src/styles.css`
- [ ] Design responsivo (mobile-first)
- [ ] Cores para feedback:
  - Verde (#22c55e) para válido
  - Vermelho (#ef4444) para inválido
- [ ] Centralizar formulário verticalmente e horizontalmente

### Passo 23: Build do Frontend

- [ ] Adicionar script no `package.json`: `"build": "tsc && cp src/*.html dist/ && cp src/*.css dist/"`
- [ ] Rodar: `cd apps/identity-web && npm install && npm run build`
- [ ] Validar que `dist/` contém `index.html`, `main.js`, `styles.css`

---

## 3.2 Embedar Assets no Binário

### Passo 24: Usar include_str! para HTML

- [ ] Em `server.rs` ou novo `assets.rs`: criar função `serve_index()`
- [ ] Embedar HTML:
  ```rust
  const INDEX_HTML: &str = include_str!("../../apps/identity-web/dist/index.html");
  pub fn serve_index() -> HttpResponse {
      HttpResponse {
          status_code: 200,
          status_text: "OK",
          content_type: "text/html; charset=utf-8",
          body: INDEX_HTML.to_string(),
      }
  }
  ```
- [ ] Testar: `curl http://localhost:8080/` deve retornar HTML

### Passo 25: Servir CSS e JS

- [ ] Embedar outros assets:
  ```rust
  const MAIN_JS: &str = include_str!("../../apps/identity-web/dist/main.js");
  const STYLES_CSS: &str = include_str!("../../apps/identity-web/dist/styles.css");
  ```
- [ ] Adicionar rotas no router:
  ```rust
  ("GET", "/static/main.js") => serve_js(),
  ("GET", "/static/styles.css") => serve_css(),
  ```
- [ ] Ajustar Content-Type: `text/javascript` e `text/css`
- [ ] **CRÍTICO:** Cache-Control com versionamento:

  ```rust
  // Opção 1: Sem cache (desenvolvimento)
  "Cache-Control: no-cache"

  // Opção 2: Cache com hash na URL (produção)
  // Renomear assets: main-abc123.js, styles-def456.css
  "Cache-Control: public, max-age=31536000, immutable"
  ```

- [ ] **Recomendação:** Usar `no-cache` até implementar versionamento automático

### Passo 26: Teste End-to-End Completo

- [ ] Rebuild backend: `cargo build --release`
- [ ] Rodar binário: `./target/release/api`
- [ ] Abrir no navegador: `http://localhost:8080`
- [ ] Testar validação com CPFs válidos e inválidos
- [ ] Validar que CSS está sendo aplicado
- [ ] Testar em mobile (DevTools responsive mode)

---

**Anterior:** [02-camada-logica.md](02-camada-logica.md)
**Próximo:** [04-camada-deploy.md](04-camada-deploy.md)
