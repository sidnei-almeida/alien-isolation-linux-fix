# Alien: Isolation — correção de FPS no Linux (Proton / DXVK)

**[English](README.md)**

Resolve as quedas pesadas e sem explicação de FPS no *Alien: Isolation* no
Linux, aquelas em que a GPU fica em 30–45 % de uso, nenhum núcleo da CPU
satura, e mesmo assim o frame rate despenca em certas áreas (as estações do
tram em Sevastopol são o caso clássico).

Uma linha de configuração do DXVK. Sem launch options, sem mods, sem wrappers.

| Cena                            | Antes    | Depois      |
|---------------------------------|----------|-------------|
| Estação do tram, olhando pra fora | 40–50  | 120–130     |
| Uso de GPU nessa cena           | 31–45 %  | ~100 %      |

Medido no setup listado em [Testado em](#testado-em).

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/sidnei-almeida/alien-isolation-linux-fix/main/install.sh | bash
```

O script procura o jogo em todas as bibliotecas do Steam (inclusive Steam
Flatpak e Snap) e nos caminhos comuns do Heroic, Lutris e Bottles, e grava um
`dxvk.conf` ao lado do `AI.exe`. Depois é só reiniciar o jogo.

Outras opções:

```bash
# Jogo instalado em lugar incomum
./install.sh --path "/mnt/games/SteamLibrary/steamapps/common/Alien Isolation"

# Ver o que mudaria sem alterar nada
./install.sh --dry-run

# Desfazer
./install.sh --uninstall
```

Se já existir um `dxvk.conf`, o script mantém as outras configurações, faz
backup em `dxvk.conf.bak` e só adiciona ou substitui a chave necessária.

### Instalação manual

Crie um arquivo chamado `dxvk.conf` na pasta do jogo (a que tem o `AI.exe`)
com o conteúdo:

```ini
d3d11.cachedDynamicResources = a
```

Ou, se preferir launch option no Steam em vez de arquivo:

```
DXVK_CONFIG="d3d11.cachedDynamicResources = a" %command%
```

## O que está acontecendo

O Alien: Isolation (2014, engine própria da Creative Assembly) atualiza muitos
buffers dinâmicos do D3D11 a cada frame e, como vários engines da época,
**lê alguns deles de volta na CPU**.

Com Resizable BAR ligado, o DXVK coloca recursos dinâmicos em VRAM visível
pelo host. Escrever ali é rápido, mas cada leitura da CPU nessa memória
atravessa o PCIe e custa centenas de vezes mais que ler da RAM. A thread de
render trava nessas leituras, a GPU fica esperando o próximo command buffer, e
nada aparece como "100 % ocupado" em lugar nenhum: é latência pura.

`d3d11.cachedDynamicResources = a` manda o DXVK alocar todos os recursos
dinâmicos em memória de sistema com cache, o que deixa as leituras baratas de
novo. O DXVK documenta essa opção como contorno exatamente pra esse tipo de
comportamento de aplicação.

### Como a causa foi encontrada

Tudo o mais foi descartado antes, com números idênticos em cada caso:

- remover todos os mods (ReShade, Alias Isolation, mouse fix);
- Enhanced Graphics / LOD em Low, Planar Reflections off, Volumetric Lighting off;
- `maxFrameLatency` do DXVK;
- limitar o Wine aos 6 núcleos físicos (`WINE_CPU_TOPOLOGY`);
- fsync no lugar de ntsync (`PROTON_NO_NTSYNC=1`);
- latência de saída dos C-states da CPU.

Uma amostra de `perf` no processo do jogo mostrou então ~40 % de todo o tempo
de CPU dentro do DXVK e do driver Vulkan, não no jogo, e o sistema tinha uma
janela de Resizable BAR de 16 GB, o que apontou direto pro posicionamento dos
buffers dinâmicos.

## Testado em

| Componente | Versão |
|------------|--------|
| GPU        | Intel Arc B580 (Resizable BAR ligado, BAR de 16 GB) |
| CPU        | AMD Ryzen 5 5500X3D |
| Mesa       | 26.2.4 |
| Kernel     | 7.2.5 |
| Proton     | GE-Proton 11-7 (DXVK v3.1) |
| Jogo       | versão Steam, com e sem mods |

A causa não é específica de fabricante. Qualquer GPU com Resizable BAR / SAM
ligado deve sofrer o mesmo travamento e se beneficiar da mesma correção.
Relatos de outro hardware são bem-vindos nas issues.

## Notas de compatibilidade

- Funciona com ReShade, Alias Isolation e mouse fix instalados. O `dxvk.conf`
  é lido pelo próprio DXVK, então wrappers de DLL na pasta do jogo não
  interferem.
- Funciona com qualquer Proton ou Wine que use DXVK (Proton da Steam, Proton
  GE, Heroic, Lutris, Bottles). Não faz nada com WineD3D nem no Windows.
- Se você já colocou `DXVK_CONFIG` nas launch options, pode remover; o arquivo
  substitui isso.
- Se quiser restringir o escopo, o DXVK também aceita `c` (constant buffers),
  `v` (vertex), `i` (index) e `r` (shader resources), ou qualquer combinação,
  como `cv`. O `a` foi o testado e é o padrão seguro.

## Enviar pro DXVK

Já existe um pull request adicionando isso como padrão embutido do DXVK pro
`AI.exe`: [doitsujin/dxvk#5948](https://github.com/doitsujin/dxvk/pull/5948).
Quando for aceito e chegar no Proton, ninguém mais vai precisar deste
repositório. Se você reproduzir o ganho em hardware diferente, abra uma issue
aqui com seus números; mais dados ajudam a revisão upstream.

## Licença

MIT.
