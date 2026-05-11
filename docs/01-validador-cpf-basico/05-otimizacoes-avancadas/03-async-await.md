# 5.3 Async/Await (Opcional - Requer Reescrita)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

**⚠️ AVISO:** Esta é uma **reescrita arquitetural completa**. Só considere se:

- Tráfego >100k req/s
- I/O é gargalo (muito tempo esperando disco/network)
- Justifica abandonar std lib

## Trade-offs

**Async (Tokio/async-std):**

- ✅ Escala para milhões de conexões (1 thread gerencia 10k+ conexões)
- ✅ Ideal para I/O-bound (99% esperando, 1% processando)
- ❌ Complexidade: `async`/`.await`, lifetimes complexos, runtime overhead
- ❌ Binário +2MB (Tokio é pesado)
- ❌ Debug mais difícil (stack traces assíncronos)

**Sync threads (atual):**

- ✅ Simples, debugável, previsível
- ✅ Ideal para CPU-bound (validação, criptografia)
- ✅ Binário pequeno (std lib)
- ❌ Não escala >10k conexões simultâneas

**Decisão:** Manter sync threads para este projeto (MVP). Async é overkill para validador de CPF.
