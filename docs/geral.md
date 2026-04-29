# Planejamento do Projeto: Criado por Humano (SaaS)

## 1. Infraestrutura e Setup Inicial

- **Domínio:** Registro e configuração de `criadoporhumano.com.br`.
- **Servidor (VPS):** Configuração de instância Linux (Hostinger KVM) em datacenter no Brasil para baixa latência.
- **Ambiente de Desenvolvimento:** Setup de repositório Git (ex: `criadoporhumano-saas`) e ambientes de Staging/Production.
- **Stack Tecnológica:**
  - **Backend:** Rust (Axum ou Actix-web) para processamento ultra-rápido.
  - **Frontend:** Vanilla TypeScript com framework **Lexical** (Meta).
  - **Banco de Dados:** PostgreSQL para usuários e metadados; Redis para cache de análise em tempo real.

## 2. Gestão de Usuários e Segurança

- **Autenticação:** Implementação de JWT (JSON Web Tokens) e sistema de permissões.
- **Cadastro/Login:** Fluxo de onboarding para redatores e empresas.
- **Conformidade:** Estruturação de Termos de Uso e Política de Privacidade de acordo com a LGPD (foco em dados biométricos).
- **Pagamentos:** Integração com Stripe ou Mercado Pago para planos de assinatura (SaaS).

## 3. Privacidade e Criptografia de Dados

- **Armazenamento Criptografado:** Todos os textos são armazenados com criptografia AES-256 em repouso (at rest).
- **Gerenciamento de Chaves:**
  - Chave mestra armazenada em serviço de gerenciamento seguro (AWS KMS, HashiCorp Vault, ou similar).
  - Rotação periódica de chaves (a cada 90 dias).
  - Chaves derivadas por usuário (opcional: permite usuário controlar sua própria chave).
- **Criptografia em Trânsito:** HTTPS/TLS 1.3 obrigatório para todas as comunicações.
- **Política de Retenção:**
  - Textos criptografados mantidos por período configurável (padrão: 1 ano).
  - Opção de exclusão imediata pelo usuário a qualquer momento.
  - Exclusão automática após cancelamento da conta (30 dias de grace period).
- **Dados Nunca Expostos:**
  - Textos descriptografados apenas em memória durante análise.
  - Logs nunca contêm conteúdo de texto.
  - Staff não tem acesso aos textos descriptografados.
- **Auditoria:** Log completo de acessos aos dados criptografados (quem, quando, qual operação).
- **Compliance LGPD:**
  - Termo de consentimento explícito para armazenamento.
  - Opção de portabilidade (export de todos os dados).
  - Direito ao esquecimento (delete completo).

## 4. Editor e Coleta de Biometria (Core Frontend)

- **Implementação Lexical:** Acoplamento do editor no frontend e customização de Nodes.
- **Plugin de Captura Biométrica:**
  - **Dwell Time:** Medição de quanto tempo cada tecla fica pressionada.
  - **Flight Time:** Medição do intervalo entre a liberação de uma tecla e a pressão da próxima.
  - **Mouse Tracking:** Coleta de trajetórias, velocidade e aceleração do cursor.
- **Gerenciamento de Buffer:** Armazenamento local temporário dos eventos para envio em lote (Batch) no final da sessão.

## 5. Motor de Verificação (Core Backend em Rust)

- **Ingestão de Dados:** Endpoint de alta performance para receber os logs de eventos.
- **Algoritmo de Detecção:**
  - Análise de Desvio Padrão (identificação de micro-hesitações humanas vs. constância robótica).
  - Validação de entropia de digitação.
  - Cruzamento de metadados (tempo de sessão vs. volume de caracteres).
- **Geração de Score:** Atribuição de um índice de confiança (0-100%) para a autoria humana.

## 6. Sistema de Selo e Certificação

- **Emissão de Certificado:** Geração de registro único no banco de dados com link de verificação público.
- **Widget do Selo:** Criação de um script `embed` (badge) para que o cliente exiba em seu site.
- **Página de Prova:** Interface de validação externa para terceiros conferirem o certificado de "Criado por Humano".

## 7. Lançamento e Calibragem

- **Alpha Test:** Coleta de dados com humanos reais para treinar a base do algoritmo.
- **Beta Fechado:** Acesso antecipado para agências de conteúdo parceiras.
- **Otimização de SEO:** Foco em palavras-chave como "certificado de texto humano" e "detecção de IA".

## 8. Dashboard e Interface do Usuário

- **Painel Principal:** Interface centralizada para visualizar todos os textos certificados.
- **Histórico de Análises:** Listagem com scores, datas e status de cada texto analisado.
- **Gerenciamento de Perfil Biométrico:** Visualização do baseline pessoal e evolução do padrão de digitação.
- **Biblioteca de Certificados:** Galeria com todos os certificados emitidos, opção de download e compartilhamento.
- **Estatísticas de Uso:** Gráficos de consumo (limite do plano, palavras analisadas, certificados emitidos).
- **Configurações:** Gerenciamento de conta, preferências e integrações.

## 9. Sistema de Comunicação

- **Emails Transacionais:**
  - Confirmação de cadastro e verificação de email.
  - Reset de senha e alterações de segurança.
  - Notificações de certificados emitidos.
  - Alertas de pagamento, renovação e vencimento de assinatura.
  - Avisos de limite de uso próximo ao teto do plano.
- **Provedor de Email:** Integração com SendGrid, AWS SES, ou Resend.
- **Templates:** Design responsivo e branded para todos os emails.

## 10. Monitoramento e Observabilidade

- **Logs Estruturados:** Implementação de logging JSON para aplicação e acesso (auditoria).
- **Métricas de Performance:** Monitoramento de latência, throughput, taxa de erro e uso de recursos.
- **Alertas Proativos:** Notificações automáticas para downtime, erros críticos ou anomalias.
- **Dashboards:** Visualização em tempo real de saúde do sistema.
- **Ferramentas:** Grafana + Prometheus, Sentry para error tracking, ou stack similar.

## 11. Backups e Disaster Recovery

- **Backup Automático:** Backup diário completo do PostgreSQL com retenção de 30 dias.
- **Backup de Certificados:** Armazenamento imutável de todos os certificados emitidos (compliance).
- **Testes de Recuperação:** Validação mensal do processo de restore.
- **Plano de Contingência:** Documentação de procedimentos para recuperação em caso de falha catastrófica.
- **Retenção LGPD:** Política de retenção conforme requisitos legais (mínimo de 5 anos para dados biométricos).

## 12. Rate Limiting e Anti-Abuse

- **Limite de Requisições:** Throttling por IP e por usuário autenticado.
- **Proteção contra Bots:** Implementação de CAPTCHA em endpoints sensíveis (cadastro, login).
- **Detecção de Abuso:** Identificação de padrões suspeitos (múltiplas tentativas, volume anormal).
- **Blacklist/Whitelist:** Sistema de bloqueio automático de IPs maliciosos.
- **Throttling Inteligente:** Limites diferentes por tier de assinatura.

## 13. API Pública e Integrações

- **API REST:** Endpoints documentados para integração externa (análise, certificação, consulta).
- **Autenticação API:** Sistema de API Keys com permissões granulares.
- **Webhooks:** Notificações em tempo real para eventos (certificado emitido, análise concluída).
- **SDK/Libraries:** Bibliotecas client em JavaScript/TypeScript para facilitar integração.
- **Documentação:** Portal com Swagger/OpenAPI, exemplos de código e guias de integração.

## 14. Billing e Gestão Financeira

- **Planos de Assinatura:** Estruturação de tiers (Básico, Pro, Enterprise) com limites claros.
- **Trial Period:** Período de teste gratuito de 7-14 dias sem necessidade de cartão.
- **Emissão de Faturas:** Geração automática de invoices e emissão de Nota Fiscal (integração com sistemas brasileiros).
- **Histórico de Pagamentos:** Interface para consulta de todas as transações.
- **Upgrades/Downgrades:** Fluxo self-service para mudança de plano com pro-rating.
- **Cancelamento:** Processo simplificado com retenção de dados conforme política.

## 15. Testes e Garantia de Qualidade

- **Testes Unitários:** Cobertura mínima de 80% no backend Rust (algoritmos críticos).
- **Testes de Integração:** Validação de endpoints da API e fluxos completos.
- **Testes E2E:** Automação de fluxos do usuário no frontend (Playwright ou Cypress).
- **Testes de Performance:** Load testing para garantir suporte a picos de acesso.
- **CI/CD:** Pipeline automatizado com execução de testes em cada commit.

## 16. Sistema de Suporte

- **Base de Conhecimento:** FAQ interativo e artigos de ajuda.
- **Sistema de Tickets:** Interface para abertura e acompanhamento de solicitações de suporte.
- **Documentação Técnica:** Guias para desenvolvedores (integração, API, troubleshooting).
- **Tutoriais em Vídeo:** Onboarding visual para novos usuários.
- **Chat de Suporte:** Implementação de chat ao vivo ou chatbot (pode ser fase 2).

## 17. Landing Page e Marketing

- **Site Institucional:** Página separada do app com informações sobre o produto.
- **Página de Preços:** Tabela comparativa clara dos planos e features.
- **Casos de Uso:** Exemplos práticos de aplicação (jornalismo, agências, e-commerce).
- **Depoimentos:** Social proof com casos de sucesso de clientes.
- **Blog SEO:** Artigos otimizados sobre autenticação de conteúdo, detecção de IA, etc.
- **Call-to-Action:** Fluxo otimizado para conversão (cadastro/trial).

## 18. Segurança Adicional

- **2FA (Autenticação em Dois Fatores):** Implementação de TOTP (Time-based One-Time Password) via apps como Google Authenticator ou Authy.
- **Logs de Auditoria:** Registro completo de quem acessou certificados, quando e de onde (IP, user-agent, geolocalização).
- **Criptografia de Dados Sensíveis em Repouso:** Garantir que todos os dados críticos (senhas, tokens, chaves) estejam criptografados no banco de dados.
- **HTTPS/SSL Obrigatório:** Certificado SSL/TLS válido e renovação automática (Let's Encrypt), com redirecionamento forçado HTTP → HTTPS.
- **Headers de Segurança:** Implementação de CSP (Content Security Policy), HSTS, X-Frame-Options, X-Content-Type-Options.
- **Sanitização de Inputs:** Proteção contra SQL Injection, XSS, CSRF em todos os endpoints.
- **Gestão de Senhas:** Hash com algoritmo moderno (Argon2 ou bcrypt), políticas de senha forte.

## 19. Admin Tools e Testing Lab

### Admin Dashboard

- **Visão Global:** Interface administrativa com todas as análises processadas, filtros por score, data, usuário e status.
- **Revisão Manual:** Sistema para revisar casos com score inconclusivo (40-70%) ou flagados como suspeitos.
- **Replay Biométrico:** Visualização gráfica dos padrões de digitação e mouse para análise forense.
  - Gráficos de dwell time ao longo do texto
  - Gráficos de flight time (latência entre teclas)
  - Heatmap de trajetória do mouse
- **Flags e Feedback:** Sistema para marcar falsos positivos/negativos e alimentar melhoria contínua.
- **Estatísticas Globais:**
  - Taxa de acurácia do algoritmo
  - Distribuição de scores (histograma)
  - Volume de análises por dia/semana
  - Tempo médio de processamento

### Testing Lab (Ambiente de Desenvolvimento)

- **Bot Simulator Básico:** Ferramenta que envia texto com timing perfeitamente uniforme (facilmente detectável).
- **Bot Simulator Avançado:** Adiciona variação artificial, pausas aleatórias, correções simuladas e ruído nos timings.
- **IA Adversarial:** Integração com modelos GPT para gerar padrões biométricos sintéticos que tentam imitar humanos.
- **Dataset de Validação:** Banco com 100+ sessões rotuladas manualmente (ground truth) para validação do algoritmo.
- **Replay de Sessões:** Re-processar dados históricos com novos parâmetros ou versões do algoritmo.
- **A/B Testing:** Interface para testar múltiplas versões do algoritmo em paralelo e comparar resultados.
- **Ajuste de Threshold:** Ferramenta visual para definir score mínimo (ex: 70%, 80%, 90%) com preview de impacto.

### Métricas de Performance

- **Acurácia:** (Verdadeiros Positivos + Verdadeiros Negativos) / Total
- **Precisão:** VP / (VP + Falsos Positivos) - Quando diz "humano", qual % está correto
- **Recall (Sensibilidade):** VP / (VP + Falsos Negativos) - Quantos humanos reais são detectados
- **F1-Score:** Média harmônica entre precisão e recall
- **Curva ROC:** Gráfico de trade-off entre taxa de falsos positivos e falsos negativos
- **Confusion Matrix:** Tabela detalhada de VP, VN, FP, FN

### Red Team / Pentesting

- **Scripts de Ataque:** Repositório de scripts conhecidos que tentam burlar o sistema.
- **Simulação Adversarial:** Bots sofisticados que tentam imitar padrões humanos com variação controlada.
- **Rate Limiting Test:** Verificar se proteções anti-abuse funcionam sob carga.
- **Documentação de Vulnerabilidades:** Registro de métodos que conseguiram burlar e contramedidas implementadas.
- **Continuous Testing:** Testes automatizados que rodam diariamente contra o algoritmo em produção.

---

## 20. Funcionalidades Futuras (v2.0+)

### Integrações e Extensibilidade

**Arquitetura:** Core de captura biométrica único + adapters específicos por plataforma.

- **Browser Extension Universal (PRIORIDADE v1.5):**
  - Extensão Chrome/Firefox que injeta captura biométrica em qualquer editor web.
  - Funciona automaticamente em WordPress, Medium, Notion, Google Docs, etc.
  - Uma solução única para múltiplas plataformas.
  - **Vantagem:** Controle total dos eventos de teclado/mouse independente de API limitada.

- **SDK JavaScript Base:**
  - Biblioteca core com lógica de captura biométrica (dwell/flight time, mouse tracking).
  - Reutilizada por todas as integrações nativas.
  - Comunicação padronizada com backend Rust.

- **Plugin WordPress:** Integração nativa com editor Gutenberg (maior mercado CMS).
- **Integração Google Docs:** Add-on para Google Workspace (limitação: API não expõe keystroke events, solução via mini-editor ou browser extension).
- **Integração Notion:** API para validar blocos (mesma limitação do Google Docs).
- **Integração outros CMS:** Drupal, Joomla, Wix, Squarespace via browser extension ou plugins específicos.

### Monetização Avançada

- **Sistema de Afiliados:** Programa de referral com comissões recorrentes.
- **White-label:** Versão customizável para empresas (marca própria, domínio próprio).
- **API Enterprise:** Planos corporativos com SLA garantido e suporte prioritário.

### Expansão Internacional

- **Internacionalização (i18n):** Suporte para inglês (EN), espanhol (ES), francês (FR).
- **Datacenters Regionais:** Expansão para Europa e EUA para compliance local.
- **Multi-moeda:** Suporte para USD, EUR, além de BRL.

### Experiência do Usuário

- **Mobile App Nativo:** Aplicativos iOS e Android com editor offline-first.
- **Modo Offline:** Captura biométrica local com sincronização posterior.
- **Colaboração em Tempo Real:** Múltiplos autores em um mesmo documento (similar ao Google Docs).

### Analytics e Insights

- **Dashboard Analítico:** Métricas de evolução do padrão biométrico ao longo do tempo.
- **Relatórios Customizados:** Export de dados para compliance e auditoria.
- **Benchmarking:** Comparação anônima com outros escritores do mesmo nicho.
