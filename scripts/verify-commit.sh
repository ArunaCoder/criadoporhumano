#!/bin/bash

# Pega a mensagem do commit do arquivo temporário do Git
commit_msg=$(cat "$1")

# Regex para o padrão convencional: tipo(escopo)!: descrição
# Ex: feat(utils): adiciona validador de cpf
pattern="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?:\ .+"

if [[ ! $commit_msg =~ $pattern ]]; then
  echo "🛑 Erro: Mensagem de commit fora do padrão convencional!"
  echo "Formatos aceitos: 'feat: ...' ou 'fix(scope): ...'"
  echo "Sua mensagem foi: '$commit_msg'"
  exit 1
fi

echo "✅ Mensagem de commit validada."
