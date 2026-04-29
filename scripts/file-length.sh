#!/usr/bin/env bash
# ==========================================================
# 🧾 File Length Check - Monorepo
# ----------------------------------------------------------
# Verifica se algum arquivo ultrapassa o limite definido.
# Compatível com Husky.
# ==========================================================

set -e

# ---------- CONFIGURAÇÃO PRINCIPAL -------------------------
ONLY_STAGED=true   # true = apenas arquivos staged | false = todos
# ----------------------------------------------------------

# ---------- LIMITES POR TIPO -------------------------------
MAX_TS=150         # .ts
MAX_TSX=150        # .tsx
MAX_JS=150         # .js
MAX_JSX=200        # .jsx
MAX_JSON=200       # .json
MAX_MD=300         # .md
MAX_RS=200         # .rs (Rust)
MAX_DEFAULT=300    # Qualquer outro tipo
# ----------------------------------------------------------

# Caminho absoluto para o arquivo de ignore (na mesma pasta do script)
IGNORE_FILE="$(dirname "$0")/.filelengthignore"

# ---------- FUNÇÕES AUXILIARES ----------------------------
should_ignore() {
  local file="$1"

  # Ignorar diretórios padrão
  [[ "$file" == *"node_modules/"* ]] && return 0
  [[ "$file" == *".git/"* ]] && return 0
  [[ "$file" == *"dist/"* ]] && return 0

  # Normaliza o caminho removendo './' do início
  local normalized="${file#./}"

  # Ignorar via arquivo .filelengthignore (com suporte total a glob)
  if [[ -f "$IGNORE_FILE" ]]; then
    while IFS= read -r pattern; do
      [[ -z "$pattern" || "$pattern" == \#* ]] && continue

      # Remove './' do padrão também, se houver
      local normalized_pattern="${pattern#./}"

      # Se o padrão for uma pasta (termina com /), ignora tudo dentro dela
      if [[ "$normalized" == ${normalized_pattern}* ]]; then
        return 0
      fi

      # Caso geral: comparação por glob
      if [[ "$normalized" == $normalized_pattern ]]; then
        return 0
      fi
    done < "$IGNORE_FILE"
  fi

  return 1
}



get_limit() {
  case "$1" in
    *.ts) echo "$MAX_TS" ;;
    *.tsx) echo "$MAX_TSX" ;;
    *.js) echo "$MAX_JS" ;;
    *.jsx) echo "$MAX_JSX" ;;
    *.json) echo "$MAX_JSON" ;;
    *.md) echo "$MAX_MD" ;;
    *.rs) echo "$MAX_RS" ;;
    *) echo "$MAX_DEFAULT" ;;
  esac
}
# ----------------------------------------------------------

echo "🧾 Verificando comprimento dos arquivos..."

# ---------- COLETA DE ARQUIVOS -----------------------------
if [[ "$ONLY_STAGED" == true ]]; then
  FILES=$(git diff --cached --name-only --diff-filter=ACM)
else
  FILES=$(find . -type f \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/dist/*")
fi
# ----------------------------------------------------------

if [[ -z "$FILES" ]]; then
  echo "✅ Nenhum arquivo encontrado."
  exit 0
fi

FAILED=0

while IFS= read -r file; do
  [[ ! -f "$file" ]] && continue
  should_ignore "$file" && continue

  limit=$(get_limit "$file")
  lines=$(wc -l < "$file" | tr -d ' ')

  if [[ "$lines" -gt "$limit" ]]; then
    echo "🛑 $file — $lines linhas (limite $limit)"
    FAILED=1
  fi
done <<< "$FILES"

if [[ "$FAILED" -eq 1 ]]; then
  echo "❌ Commit bloqueado: reduza o tamanho dos arquivos listados acima."
  exit 1
else
  echo "✅ Todos os arquivos dentro dos limites."
  exit 0
fi
