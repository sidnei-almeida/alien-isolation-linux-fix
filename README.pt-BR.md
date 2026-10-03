<p align="center">
  <img src="assets/banner.png" alt="Alien: Isolation — Linux FPS Fix (Proton / DXVK)" width="100%">
</p>

<h1 align="center">Alien: Isolation — Correção de FPS no Linux</h1>

<p align="center">
  Uma linha de configuração do DXVK que leva as piores cenas do jogo de 45 fps pra mais de 120 no Linux.<br>
  Sem launch options, sem mods, sem wrappers de DLL. Só um <code>dxvk.conf</code> na pasta do jogo.
</p>

<p align="center">
  <a href="https://github.com/doitsujin/dxvk/pull/5948"><img alt="PR no DXVK" src="https://img.shields.io/github/pulls/detail/state/doitsujin/dxvk/5948?label=DXVK%20PR%20%235948&logo=github"></a>
  <a href="LICENSE"><img alt="Licença: MIT" src="https://img.shields.io/badge/license-MIT-green.svg"></a>
  <img alt="Plataforma: Linux" src="https://img.shields.io/badge/platform-Linux-blue?logo=linux&logoColor=white">
  <img alt="Funciona com Proton" src="https://img.shields.io/badge/Proton%20%2F%20Wine-DXVK-orange">
  <a href="README.md"><img alt="English" src="https://img.shields.io/badge/README-English-success"></a>
</p>

---

## Sumário

- [Resumo](#resumo)
- [Eu tenho esse problema?](#eu-tenho-esse-problema)
- [Instalação](#instalação)
  - [Uma linha](#uma-linha)
  - [Opções do script](#opções-do-script)
  - [Instalação manual](#instalação-manual)
  - [Launch option em vez de arquivo](#launch-option-em-vez-de-arquivo)
- [Conferir se funcionou](#conferir-se-funcionou)
- [O que está acontecendo](#o-que-está-acontecendo)
- [Como a causa foi encontrada](#como-a-causa-foi-encontrada)
- [Testado em](#testado-em)
- [Compatibilidade e launchers](#compatibilidade-e-launchers)
- [FAQ e problemas comuns](#faq-e-problemas-comuns)
- [Status no DXVK](#status-no-dxvk)
- [Relate seus resultados](#relate-seus-resultados)
- [Créditos](#créditos)
- [Licença](#licença)

## Resumo

```bash
curl -fsSL https://raw.githubusercontent.com/sidnei-almeida/alien-isolation-linux-fix/main/install.sh | bash
```

Depois reinicie o jogo. Só isso.

| Cena (mesmo save, mesmo lugar)        | Antes     | Depois     |
|---------------------------------------|-----------|------------|
| Estação do tram, olhando pela porta   | 40–50 fps | 120–130 fps |
| Uso de GPU nessa cena                 | 31–45 %   | ~100 %     |
| Resto do jogo                         | 100–140 fps | igual    |

## Eu tenho esse problema?

Muito provavelmente, se tudo isso for verdade:

- Você roda o *Alien: Isolation* no Linux via Proton, Wine ou qualquer launcher que use DXVK.
- Em algumas áreas (as estações do tram são o caso clássico) o frame rate despenca, muitas vezes pela metade ou mais.
- Enquanto isso acontece, a GPU **não** está ocupada: 30–50 % de uso, clock no máximo, VRAM sobrando.
- Nenhum núcleo da CPU está em 100 % também. Tudo parece ocioso e o jogo continua lento.
- Baixar as configurações gráficas quase não muda nada.
- Sua GPU tem Resizable BAR / Smart Access Memory ligado (confira na BIOS, ou com `lspci -vv` procurando um BAR de vários GB na GPU).

Se a GPU *estiver* em 100 % quando o fps cai, isso é limite normal de GPU e esta correção não vai ajudar.

## Instalação

### Uma linha

```bash
curl -fsSL https://raw.githubusercontent.com/sidnei-almeida/alien-isolation-linux-fix/main/install.sh | bash
```

O script:

1. Lê o `libraryfolders.vdf` de cada instalação do Steam que conhece (nativa, Flatpak, Snap) e procura `steamapps/common/Alien Isolation/AI.exe` em cada biblioteca.
2. Também procura um `AI.exe` nos caminhos comuns do Heroic, Lutris e Bottles.
3. Grava um `dxvk.conf` ao lado de cada `AI.exe` encontrado, com a correção.
4. Se já existir um `dxvk.conf`, mantém todas as outras configurações, faz backup em `dxvk.conf.bak` e só adiciona ou substitui a chave necessária.

É idempotente: rodar de novo mostra "Already installed" e não muda nada. Nunca precisa de `sudo`.

Prefere ler antes de rodar? Clone o repositório e execute `./install.sh` localmente. São uns 150 linhas de bash puro.

### Opções do script

```bash
# O jogo está em um lugar que o script não procura
./install.sh --path "/mnt/games/SteamLibrary/steamapps/common/Alien Isolation"

# Várias cópias (ex.: Steam e GOG)
./install.sh --path "/caminho/um" --path "/caminho/dois"

# Mostrar o que seria feito sem alterar nada
./install.sh --dry-run

# Remover a correção (mantém outras configurações do dxvk.conf)
./install.sh --uninstall
```

### Instalação manual

Crie um arquivo chamado `dxvk.conf` na pasta do jogo (a que contém o `AI.exe`) com este conteúdo:

```ini
d3d11.cachedDynamicResources = a
```

Ou simplesmente copie o [`dxvk.conf`](dxvk.conf) deste repositório pra essa pasta.

Caminhos típicos:

| Launcher          | Pasta |
|-------------------|-------|
| Steam (nativo)    | `~/.local/share/Steam/steamapps/common/Alien Isolation/` |
| Steam (Flatpak)   | `~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Alien Isolation/` |
| Outra biblioteca  | `<biblioteca>/steamapps/common/Alien Isolation/` |
| Heroic (GOG/Epic) | onde você escolheu na instalação, geralmente em `~/Games/Heroic/` |

### Launch option em vez de arquivo

Se preferir não mexer na pasta do jogo, esta launch option no Steam faz a mesma coisa:

```
DXVK_CONFIG="d3d11.cachedDynamicResources = a" %command%
```

Mantenha as outras launch options que já usa; é só colocar isso antes do `%command%`.

## Conferir se funcionou

Adicione o HUD do DXVK nas launch options uma vez, pra ler os números dentro do jogo:

```
DXVK_HUD=fps,gpuload %command%
```

Carregue um save numa estação do tram, fique parado na porta aberta e olhe pra plataforma. Antes da correção o HUD mostra algo como 45 fps com GPU em uns 40 %. Depois, deve passar bem de 100 fps com a GPU perto de 100 % (ou travado na taxa do monitor, se o V-Sync estiver ligado).

Dá pra confirmar também que o DXVK leu o arquivo rodando o jogo uma vez com `DXVK_LOG_LEVEL=info` e procurando a linha `cachedDynamicResources` no log que ele imprime no stderr (ou em `AI_d3d11.log`, se `DXVK_LOG_PATH` estiver definido).

Depois tire o HUD das launch options.

## O que está acontecendo

O *Alien: Isolation* (2014) roda no engine próprio da Creative Assembly. Como muitos engines da época, ele atualiza um monte de **buffers dinâmicos do Direct3D 11 a cada frame** e, o ponto crucial, **lê alguns deles de volta na CPU** (`Map` com acesso de leitura, ou escritas seguidas de leituras na mesma memória mapeada).

No Windows, com driver nativo, isso é barato. No DXVK, recursos dinâmicos vão pro tipo de memória que o DXVK considera melhor pra *escrita*. Quando a GPU expõe uma janela grande de Resizable BAR, esse tipo é **VRAM visível pelo host**: a CPU escreve direto nela e a GPU lê sem cópia. Ótimo pra escrever.

Mas cada *leitura* da CPU em VRAM visível pelo host é uma transação sem cache atravessando o PCIe. É centenas de vezes mais lenta que ler da RAM. A thread de render do jogo faz milhares dessas leituras por frame nas cenas pesadas, então passa a maior parte do tempo travada esperando memória. Ela não está "ocupada" no sentido que um profiler mostra, está *esperando*. A GPU, que só recebe trabalho quando a thread de render termina, fica ociosa a maior parte do frame. Por isso nada parece saturado e o fps despenca mesmo assim.

`d3d11.cachedDynamicResources = a` manda o DXVK alocar **todos** os recursos dinâmicos em memória de sistema com cache. Escrever fica um pouco mais caro (a GPU passa a ler pelo PCIe), mas as leituras da CPU voltam à velocidade da RAM, e neste jogo é essa a troca que importa. O DXVK documenta a opção como contorno exatamente pra esse tipo de comportamento, e vários outros títulos já vêm com ela como padrão por jogo (Crysis 3, Monster Hunter World, Kingdom Come: Deliverance, Darksiders, …).

## Como a causa foi encontrada

O sintoma ("nada satura, tudo é lento") bate com muitas causas possíveis, então tudo que era mais barato de testar foi descartado primeiro. Cada item abaixo deu números **idênticos** no mesmo lugar:

| Hipótese | Teste | Resultado |
|----------|-------|-----------|
| Mods (ReShade, Alias Isolation, mouse fix) | rodar sem os overrides de DLL | igual |
| Passes de render caros | LOD/Enhanced Graphics Low, Planar Reflections off, Volumetric Lighting off | igual |
| Pipelining CPU→GPU | `dxgi.maxFrameLatency = 3` | igual |
| Escalonamento de threads / SMT | `WINE_CPU_TOPOLOGY=6:0,2,4,6,8,10` (só núcleos físicos) | igual |
| Primitivas de sincronização do Wine | `PROTON_NO_NTSYNC=1` (fsync no lugar de ntsync) | igual, GPU caiu ainda mais |
| Latência de acordar a CPU | latências de saída dos C-states | C2 sai em 18 µs, não é isso |
| Contenção de threads | contagem de syscalls de espera por frame | nada anormal |

O que finalmente apontou o caminho certo:

1. Um `perf record -p <pid>` no processo do jogo mostrou uns **40 % de todo o tempo de CPU dentro do `d3d11.dll` (DXVK) e do `libvulkan_intel.so`**, não no código do jogo. Fosse o que fosse, o DXVK estava no meio.
2. O `lspci -vv` mostrou a GPU com **BAR de 16 GB**, ou seja, Resizable BAR ligado, que é exatamente a condição em que o DXVK coloca buffers dinâmicos em VRAM visível pelo host.
3. A documentação do próprio `dxvk.conf` descreve `cachedDynamicResources` como o ajuste pra "aplicações com bug" que leem buffers dinâmicos de volta.

Um lançamento com a opção ligada, mesmo save, mesma porta: 45 fps → 128 fps, GPU de 40 % pra 100 %.

## Testado em

| Componente | Versão |
|------------|--------|
| GPU        | Intel Arc B580 (Resizable BAR ligado, BAR de 16 GB) |
| CPU        | AMD Ryzen 5 5500X3D |
| Mesa       | 26.2.4 (driver Vulkan ANV) |
| Kernel     | 7.2.5 |
| Proton     | GE-Proton 11-7, com DXVK v3.1 |
| Jogo       | versão Steam, testado com e sem ReShade / Alias Isolation / mouse fix |

A causa não é específica de fabricante. Qualquer GPU com Resizable BAR ou Smart Access Memory ligado (AMD, NVIDIA, Intel) deve sofrer o mesmo travamento e se beneficiar da mesma correção. Relatos de outro hardware são muito bem-vindos, veja [Relate seus resultados](#relate-seus-resultados).

## Compatibilidade e launchers

| Setup | Funciona? | Observações |
|-------|-----------|-------------|
| Steam + Proton (Valve ou GE) | ✅ | o `dxvk.conf` é lido automaticamente |
| Steam Flatpak / Snap | ✅ | o instalador procura nesses caminhos |
| Heroic (GOG / Epic) | ✅ | DXVK vem ligado; coloque o `dxvk.conf` ao lado do `AI.exe` |
| Lutris | ✅ | confira se o DXVK está ativado nas opções do runner |
| Bottles | ✅ | confira se o DXVK está ativado na bottle |
| Wine puro com DXVK | ✅ | mesmo arquivo, mesmo lugar |
| Wine com WineD3D (sem DXVK) | ❌ | a opção é do DXVK; instale o DXVK primeiro |
| Windows | ❌ | não se aplica, o D3D11 nativo não tem esse problema |
| ReShade / Alias Isolation / mouse fix | ✅ | wrappers de DLL na pasta não interferem; quem lê o arquivo é o DXVK |

Se você já tem `DXVK_CONFIG=...` nas launch options de algum contorno anterior, pode remover. O arquivo torna isso redundante.

## FAQ e problemas comuns

**O script diz que não achou o `AI.exe`.**
Passe a pasta explicitamente com `--path "/seu/caminho/Alien Isolation"`. Usuários de Steam Flatpak com bibliotecas em outros discos: o instalador lê o `libraryfolders.vdf`, mas se o disco não estiver montado ele não vai enxergar.

**Instalei e nada mudou.**
Confirme que o arquivo está mesmo ao lado do `AI.exe` (`ls "<pasta do jogo>/dxvk.conf"`), que reiniciou o jogo, e que está realmente rodando com DXVK (Proton sempre está; Lutris/Bottles só se estiver ativado). Depois veja a seção [Conferir se funcionou](#conferir-se-funcionou). Se a GPU já estava em ~100 % antes, o gargalo é outro.

**Uma atualização do jogo ou o "verificar integridade" do Steam vai apagar?**
Verificar integridade só mexe em arquivos que fazem parte do depot, então o `dxvk.conf` sobrevive. Uma reinstalação completa apaga a pasta; é só rodar o instalador de novo.

**Piora o desempenho em algum lugar?**
Não neste jogo, nos nossos testes. Cenas que já eram limitadas pela GPU continuaram iguais. A documentação do DXVK avisa que a opção "pode reduzir o desempenho limitado por GPU" em geral, e é por isso que é uma configuração por jogo e não um padrão global.

**Posso usar algo mais restrito que `a`?**
Sim. O DXVK aceita qualquer combinação de `v` (vertex buffers), `i` (index buffers), `c` (constant buffers) e `r` (shader resources), ex.: `cv`. O `a` foi o medido e é o padrão seguro. Se testar subconjuntos, relate os números.

**Uso Vortex / gerenciador de mods. Vai reclamar?**
Não. O `dxvk.conf` é um arquivo não gerenciado; o Vortex ignora arquivos que não foi ele que colocou.

**Não tenho Resizable BAR. Preciso disso?**
Provavelmente não, mas é inofensivo. Sem ReBAR o DXVK já mantém a maioria dos buffers dinâmicos em memória de sistema e as leituras são baratas.

**Posso usar só a launch option?**
Sim, veja [Launch option em vez de arquivo](#launch-option-em-vez-de-arquivo). O arquivo é só mais durável e independe de launcher.

## Status no DXVK

O lugar certo pra essa correção é dentro do próprio DXVK, como padrão por jogo, pra sair com cada versão do Proton e ninguém precisar deste repositório.

- **Pull request:** [doitsujin/dxvk#5948](https://github.com/doitsujin/dxvk/pull/5948) — adiciona `d3d11.cachedDynamicResources = a` pro `AI.exe` em `src/util/config/config.cpp`.

Quando for aceito e chegar ao Proton, este repo vira uma conveniência pra quem usa Proton antigo. O badge no topo da página acompanha o estado do PR.

## Relate seus resultados

Dados de outro hardware facilitam a revisão upstream e ajudam a confirmar que a correção é universal. [Abra uma issue](https://github.com/sidnei-almeida/alien-isolation-linux-fix/issues/new?template=results.md) com:

- Modelo da GPU e se Resizable BAR / SAM está ligado
- CPU
- Distro, kernel, versão do Mesa ou do driver NVIDIA
- Versão do Proton / Wine (e do DXVK, se souber)
- fps e uso de GPU na porta de uma estação do tram **antes** e **depois**, lidos com `DXVK_HUD=fps,gpuload`

Há um template de issue com esses campos prontos pra preencher.

## Créditos

- [DXVK](https://github.com/doitsujin/dxvk), de Philip Rebohle e colaboradores, pela camada de tradução pra Vulkan e por manter uma válvula de escape configurável pra engines como este.
- [Proton](https://github.com/ValveSoftware/Proton) e [Proton GE](https://github.com/GloriousEggroll/proton-ge-custom).
- [Alias Isolation](https://github.com/aliasIsolation/aliasIsolation) e a comunidade de mods do Alien: Isolation, cujo trabalho fez valer a pena correr atrás desses últimos frames.
- Diagnosticado no [Omarchy](https://omarchy.org) (Arch Linux) com `perf`, `strace` e muito tempo parado na porta de um tram.

## Licença

[MIT](LICENSE). Faça o que quiser; um link de volta é bem-vindo.
