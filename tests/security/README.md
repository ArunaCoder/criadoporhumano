# Security Tests

Testes de segurança e penetração para validar robustez dos serviços.

## ⚠️ AVISO LEGAL

Estes scripts destinam-se **exclusivamente** a testes em ambientes próprios/controlados.
Usar contra sistemas sem autorização explícita é **ilegal** e **antiético**.

## 🚀 Quick Start (Shell Scripts)

**Novos scripts executáveis** para testes rápidos sem problemas de copy/paste:

```bash
# Terminal 1: Iniciar servidor
cd backend/api
cargo run

# Terminal 2: Executar testes
./tests/security/run-all-tests.sh              # Todos os testes
./tests/security/test-legitimate.sh            # Baseline (deve funcionar)
./tests/security/test-path-traversal.sh        # Path traversal attacks
./tests/security/test-headers.sh               # Header bombs
./tests/security/test-methods.sh               # HTTP methods
```

**Output colorido:**

- 🟢 Verde = Comportamento correto (bloqueado ou aceito conforme esperado)
- 🔴 Vermelho = Vulnerabilidade ou erro
- 🟡 Amarelo = Resultado inesperado

---

## Scripts Disponíveis

### Shell Scripts (`.sh`)

**Executáveis prontos** para testes manuais rápidos:

- `run-all-tests.sh` — Executa suite completa
- `test-legitimate.sh` — Requisições válidas (baseline)
- `test-path-traversal.sh` — 7 variações de path traversal
- `test-headers.sh` — Header bombs e giant headers
- `test-methods.sh` — Métodos HTTP permitidos/proibidos

**Referência completa:** Ver [curl-test-commands.md](curl-test-commands.md)

---

### `dos_attack_test.py`

Testa vulnerabilidade de buffer overflow em servidores HTTP que usam `read_line()` sem limite de tamanho.

**Vulnerabilidade Alvo:**

- Servidores que leem requisições HTTP linha por linha sem `BufReader::with_capacity()`
- Código vulnerável: `String::new()` + `stream.read_line(&mut buffer)` em loop

**Como Funciona:**

1. Conecta ao servidor alvo
2. Envia chunks de dados **sem newline** (`\n`) continuamente
3. Força o buffer do servidor a crescer ilimitadamente na Heap
4. Monitora taxa de envio e estatísticas

**Uso:**

```bash
# Teste básico em localhost:8080
python dos_attack_test.py

# Customizar target e porta
python dos_attack_test.py -t 192.168.1.50 -p 3000

# Chunks maiores (5MB) com delay
python dos_attack_test.py -c 5242880 -d 0.1

# Ver todas as opções
python dos_attack_test.py --help
```

**Validação de Sucesso:**

- Monitorar consumo de RAM do processo servidor (Task Manager / htop)
- Servidor deve crashar com OOM (Out of Memory) se vulnerável
- Servidor protegido deve limitar buffer ou fechar conexão

**Monitoramento em Tempo Real (Windows PowerShell):**

```powershell
# Abra PowerShell e rode este comando antes de iniciar o ataque
while($true) {
    Get-Process api -ErrorAction SilentlyContinue |
    Select-Object Name, @{Name="RAM(MB)";Expression={[math]::Round($_.WS/1MB,2)}}, @{Name="CPU(%)";Expression={$_.CPU}}
    Start-Sleep -Seconds 1
    Clear-Host
}
```

**Fluxo Completo de Teste:**

1. **PowerShell:** Execute o comando acima (ficará atualizando métricas)
2. **Terminal 1:** `cargo run` no diretório `backend/api/`
3. **Terminal 2:** `python dos_attack_test.py` em `tests/security/`
4. **Observe:** RAM deve permanecer estável (~2-5 MB) se protegido, ou crescer exponencialmente se vulnerável

**Mitigações Esperadas:**

- Usar `BufReader::with_capacity(MAX_SIZE)` no Rust
- Implementar timeout de leitura
- Limitar tamanho total de requisição
- Rate limiting por IP

## Estrutura

```
tests/security/
├── README.md              ← Este arquivo
├── dos_attack_test.py     ← Teste de buffer overflow
└── [futuros testes]
```

## Dependências

```bash
# Python 3.7+, stdlib apenas (socket, argparse, time, signal)
python3 dos_attack_test.py
```

## Integração CI/CD

Para testes automatizados, considere:

1. **Ambiente isolado** (container/VM com resource limits)
2. **Validação positiva**: servidor com mitigação deve sobreviver
3. **Validação negativa**: servidor vulnerável (test fixture) deve crashar

```yaml
# Exemplo (não implementado ainda)
- name: Security Tests
  run: |
    docker run --rm --memory=256m vulnerable-server &
    python tests/security/dos_attack_test.py -c 524288
    # Assert: servidor crashou em <10s
```

---

**Mantido por:** DevOps/Security Team
**Última Atualização:** 2026-05-05
