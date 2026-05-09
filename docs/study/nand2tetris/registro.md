**09/05/2026**

# Part I - Introdução: Hardware

<https://drive.google.com/file/d/1CuvVy2-58iMzs47xEwxkH8npcORnqj5Y/view>

A principal habilidade em ciência da computação é saber diferenciar `abstração` de `implementação`. Enquanto a abstração é `o que faz`, a implementação é `como faz`. Isso permite separar o projeto em `módulos` gerenciáveis, onde se ignora como a base funciona, até que a abstração esteja completa e se possa abstrair a base também. Exemplo: eu posso escrever um programa que conversa com o sistema operacional sem precisar entender como o sistema operacional funciona, ou vice versa: eu posso projetar um sistema operacional sem precisar entender cada uma das linguagens que um dia será utilizada para conversar com ele. Basta haver uma `interface` entre os dois.

**Módulo:** Um subsistema bem especificado que pode ser implementado e testado unitariamente de forma independente de outros módulos.

**Design modular:** Dividir um sistema complexo em um "bom" conjunto de módulos.

> Uma vez que você entender a abstração do módulo (um mundo rico por si só), você prosseguirá para implementá-lo de fato, usando blocos de construção abstratos do nível abaixo.

> O design modular é uma arte adquirida, lapidada ao ver e implementar muitas abstrações bem projetadas.

# Part I1: Boolean Logic

<https://b1391bd6-da3d-477d-8c01-38cdf774495a.filesusr.com/ugd/44046b_f2c9e41f0b204a34ab78be0ae4953128.pdf>

> Visto que o hardware do computador é baseado na representação e manipulação de valores binários, as funções booleanas desempenham um papel central na especificação, construção e otimização de arquiteturas de hardware.

Uma `função binária` transforma `n` entradas binárias (`0 ou 1`, `true ou false`, etc.) em um resultado binário. Por exemplo f(x,y,z) = (x + y) • !z. Nessa notação, `+` significa OR e `•` significa AND. Assim, essa função define que quando x OU y (inclusive os dois) for true e, ao mesmo tempo, z é false, o resultado da função será true. Isso pode ser expresso numa tabela da verdade com as colunas sendo x, y, z e f(x,y,z), ou de forma canônica, por exemplo, `f(x,y,z) = !xy!z + x!y!z + xy!z`.

> Esta construção leva a uma conclusão importante: Toda função booleana, não importa quão complexa, pode ser expressa usando apenas três operadores booleanos: And, Or e Not.

Para cada `n` variáveis binárias, existem `2^2^n` funções lógicas que podem ser definidas. Por exemplo, para apenas uma variável boleana x, n=1 e o número de funções é 4: `sempre ligado`, `sempre desligado`, `identidade` e `contrário`.

Com duas variáveis, já temos 16 funções possíveis:

| Function    | Expression    | x=0, y=0 | x=0, y=1 | x=1, y=0 | x=1, y=1 |
| :---------- | :------------ | :------: | :------: | :------: | :------: |
| Constant 0  | 0             |    0     |    0     |    0     |    0     |
| And         | x · y         |    0     |    0     |    0     |    1     |
| x And Not y | x · ȳ         |    0     |    0     |    1     |    0     |
| x           | x             |    0     |    0     |    1     |    1     |
| Not x And y | x̄ · y         |    0     |    1     |    0     |    0     |
| y           | y             |    0     |    1     |    0     |    1     |
| Xor         | x · ȳ + x̄ · y |    0     |    1     |    1     |    0     |
| Or          | x + y         |    0     |    1     |    1     |    1     |
| Nor         | !{x + y}      |    1     |    0     |    0     |    0     |
| Equivalence | x · y + x̄ · ȳ |    1     |    0     |    0     |    1     |
| Not y       | ȳ             |    1     |    0     |    1     |    0     |
| If y then x | x + ȳ         |    1     |    0     |    1     |    1     |
| Not x       | x̄             |    1     |    1     |    0     |    0     |
| If x then y | x̄ + y         |    1     |    1     |    0     |    1     |
| Nand        | !{x · y}      |    1     |    1     |    1     |    0     |
| Constant 1  | 1             |    1     |    1     |    1     |    1     |

`Nand` e `Nor` tem uma característica particular: combinando ela com ela mesma em diferentes estruturas, ela pode ter o mesmo efeito lógico que AND, OR ou NOT. E como cada função binária, não importa sua complexidade, pode ser reduzida a múltiplas instruções com AND, OR e NOT, isso significa que a função Nand ou Nor pode sozinha construir qualquer outra função, por exemplo, `x Or y = (x Nand x) Nand (y Nand y)`.
**(x Nand x)** é o mesmo que !{x · x}, ou seja, NOT(x AND x) ou seja, NOT x.

**Gate (porta)** é um dispositivo físico (elétrico, magnético, biológico... etc.) que implementa uma função boleana. Um `transistor` é um componente que contrói um gate. E um `chip` é um conjunto de transistores. Por exemplo, para criar uma porta Nand, precisamos de uma combinação específica de transistores que garanta a saída lógica correta conforme a tabela verdade.

> A arte do design lógico pode ser descrita da seguinte forma: Dada uma especificação de porta (interface), encontre uma maneira eficiente de implementá-la usando outras portas que já foram implementadas.

continuar em 1.1.3 Actual Hardware Construction
