use std::env;
use std::path::PathBuf;

pub mod http;

pub struct ServerConfig {
    pub base_canonical: PathBuf,
}

impl ServerConfig {
    pub fn new(custom_dir: Option<String>) -> Result<Self, String> {
        let dir_name = custom_dir
            .or_else(|| env::var("PUBLIC_DIR").ok())
            .unwrap_or_else(|| "public".to_string());

        let base_canonical = PathBuf::from(&dir_name)
            .canonicalize()
            .map_err(|e| format!("ERRO CRÍTICO: Caminho {} inacessível: {}", dir_name, e))?;

        Ok(Self { base_canonical })
    }
}
/*O pensamento aqui é simples: se você não controla o seu ambiente, você não controla o seu software. Um servidor que assume caminhos de arquivos sem validar se eles existem no hardware é uma bomba-relógio.

Aqui está o monólogo técnico de como esse código foi concebido:

1. A Estrutura de Dados (O Esqueleto)
"Preciso de uma struct": Porque quero agrupar o estado da configuração em um único objeto coerente. Não quero variáveis soltas pelo sistema; quero uma fonte da verdade única para o servidor.

"O campo base_canonical deve ser pub": Porque outros módulos (como o meu roteador ou o motor de busca de arquivos) precisarão ler esse caminho para saber onde buscar o HTML/JS. Ele é público para leitura, mas imutável após a criação.

"O tipo deve ser PathBuf": Jamais usaria uma String aqui. Uma String é apenas uma sequência de bytes UTF-8. Um PathBuf é uma estrutura que entende as regras do Sistema Operacional (separadores / vs \, limites de caracteres). É o tipo correto para manipulação de arquivos no disco.

2. A Implementação (impl)
"Uso a palavra impl": Para manter o comportamento (funções) próximo aos dados (struct). É organização modular.

"O método deve ser pub fn new": É o padrão Constructor em Rust. Ele é público porque é o ponto de entrada para qualquer um que deseje instanciar o servidor.

"Retorno Result<Self, String>": Aqui está o rigor. Eu não retorno um objeto "quebrado". Ou o servidor recebe uma configuração válida (Ok(Self)), ou ele morre com uma mensagem clara (Err(String)). O programa nem deve tentar alocar memória se o diretório base for inválido.

3. A Lógica de Prioridade (O Fallback)
"Preciso de uma cascata de decisão":

Primeiro, verifico o custom_dir. Se quem me chamou passou um caminho, a palavra dele é a lei.

Se não, verifico o ambiente (env::var). Isso permite mudar o comportamento do binário via Shell ou Docker sem recompilar o código. É flexibilidade sem custo.

Por fim, o literal "public". É a convenção sensata. Se nada for dito, olhamos para a pasta padrão.

4. A Validação Soberana (.canonicalize())
"Aqui é onde o código aperta a mão do Hardware": Eu não confio em strings. O método .canonicalize() faz uma chamada de sistema (syscall). Ela resolve caminhos relativos para absolutos e, mais importante, valida a existência física.

Se o diretório for uma mentira, o SO me avisa agora, no boot.

5. O Tratamento de Erro (.map_err e ?)
"Uso o operador ?": Para propagar a falha. Se o caminho for inacessível, eu interrompo o fluxo. Não quero "tratamento de erro" genérico; quero um Erro Crítico que explique exatamente por que o sistema falhou ao subir.

Resultado final: No final do processo, tenho um base_canonical que é um caminho absoluto, validado pelo sistema operacional, limpo de ataques de segurança e pronto para servir arquivos com custo de processamento zero em tempo de execução.
 */
