#!/bin/bash

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\n${GREEN}📦 Arquivos adicionados ao stage.${NC}"

# 1. Verificação de arquivos ignorados
IGNORED_STAGED=$(git check-ignore $(git diff --cached --name-only) 2>/dev/null || true)

if [ -n "$IGNORED_STAGED" ]; then
  echo -e "${RED}⚠️ ATENÇÃO: Você adicionou arquivos que estão no seu .gitignore:${NC}"
  echo "$IGNORED_STAGED"
  echo -e "${YELLOW}Dica: Use 'git reset <arquivo>' para removê-los do stage.${NC}\n"
fi

# 2. Guia de Padrões Convencionais
echo -e "${BLUE}📖 Guia de Convenção (Conventional Commits):${NC}"
echo "------------------------------------------------------------"
printf "%-12s | %s\n" "TIPO" "DESCRIÇÃO"
echo "------------------------------------------------------------"
printf "${GREEN}%-12s${NC} | %s\n" "feat"     "Nova funcionalidade ou incremento no sistema"
printf "${GREEN}%-12s${NC} | %s\n" "fix"      "Correção de um erro, bug ou falha"
printf "%-12s | %s\n" "docs"     "Alterações apenas em arquivos de documentação"
printf "%-12s | %s\n" "style"    "Ajustes de formatação, lints e pontos (sem mudança de lógica)"
printf "%-12s | %s\n" "refactor" "Mudança no código que não altera comportamento final"
printf "%-12s | %s\n" "perf"     "Alteração de código focada em ganho de performance"
printf "%-12s | %s\n" "test"     "Adição de novos testes ou correção de existentes"
printf "%-12s | %s\n" "build"    "Mudanças no sistema de build ou dependências externas"
printf "%-12s | %s\n" "ci"       "Alterações em scripts e arquivos de configuração de CI"
printf "%-12s | %s\n" "chore"    "Manutenções gerais que não afetam src ou testes"
printf "%-12s | %s\n" "revert"   "Reversão de um commit anterior"
echo "------------------------------------------------------------"

# 3. Instrução de Fechamento
echo -e "\n${BLUE}💡 Comando recomendado:${NC}"
echo -e "git commit -m \"tipo(escopo): descrição curta\"\n"
