# Alien: Isolation — Linux FPS fix (Proton / DXVK)

**[Português (Brasil)](README.pt-BR.md)**

Fixes the heavy, unexplained FPS drops in *Alien: Isolation* on Linux where the
GPU sits at 30–45 % load, no CPU core is saturated, and the frame rate still
collapses in certain areas (the Sevastopol tram stations are the classic case).

One line of DXVK configuration. No launch options, no mods, no wrappers.

| Scene                       | Before   | After       |
|-----------------------------|----------|-------------|
| Tram station, looking out   | 40–50    | 120–130     |
| GPU load in that scene      | 31–45 %  | ~100 %      |

Measured on the setup listed under [Tested on](#tested-on).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sidnei-almeida/alien-isolation-linux-fix/main/install.sh | bash
```

The script finds the game in every Steam library (including Flatpak and Snap
Steam), as well as common Heroic, Lutris and Bottles locations, and writes a
`dxvk.conf` next to `AI.exe`. Restart the game afterwards.

Other options:

```bash
# Game installed somewhere unusual
./install.sh --path "/mnt/games/SteamLibrary/steamapps/common/Alien Isolation"

# See what would change without touching anything
./install.sh --dry-run

# Revert
./install.sh --uninstall
```

If a `dxvk.conf` already exists, the script keeps its other settings, backs it
up to `dxvk.conf.bak`, and only adds or replaces the one key it needs.

### Manual install

Create a file named `dxvk.conf` in the game folder (the one with `AI.exe`)
containing:

```ini
d3d11.cachedDynamicResources = a
```

Or, if you prefer a Steam launch option instead of a file:

```
DXVK_CONFIG="d3d11.cachedDynamicResources = a" %command%
```

## What is going on

Alien: Isolation (2014, Creative Assembly's in-house engine) updates a lot of
dynamic D3D11 buffers every frame and, like many engines of its time, **reads
some of them back on the CPU**.

With Resizable BAR enabled, DXVK places dynamic resources in host-visible
VRAM. Writes are fast, but every CPU read from that memory crosses PCIe and
is hundreds of times slower than a read from system RAM. The render thread
stalls on those reads, the GPU starves waiting for the next command buffer,
and nothing shows up as "100 % busy" anywhere: it is pure latency.

`d3d11.cachedDynamicResources = a` tells DXVK to allocate all dynamic
resources in cached system memory instead, which makes the readbacks cheap
again. DXVK documents this option as a workaround for exactly this kind of
application behaviour.

### How the culprit was found

Everything else was ruled out first, with identical numbers in each case:

- removing all mods (ReShade, Alias Isolation, mouse fix);
- Enhanced Graphics / LOD on Low, Planar Reflections off, Volumetric Lighting off;
- DXVK `maxFrameLatency`;
- limiting Wine to the 6 physical cores (`WINE_CPU_TOPOLOGY`);
- fsync instead of ntsync (`PROTON_NO_NTSYNC=1`);
- CPU C-state exit latency.

A `perf` sample of the game process then showed ~40 % of all CPU time inside
DXVK and the Vulkan driver rather than the game, and the system had a 16 GB
Resizable BAR window, which pointed straight at the dynamic-buffer placement.

## Tested on

| Component | Version |
|-----------|---------|
| GPU       | Intel Arc B580 (Resizable BAR on, 16 GB BAR) |
| CPU       | AMD Ryzen 5 5500X3D |
| Mesa      | 26.2.4 |
| Kernel    | 7.2.5 |
| Proton    | GE-Proton 11-7 (DXVK v3.1) |
| Game      | Steam build, with and without mods |

The root cause is not vendor-specific. Any GPU with Resizable BAR / SAM
enabled should hit the same stall and benefit from the same fix. Reports from
other hardware are welcome in the issues.

## Compatibility notes

- Works with ReShade, Alias Isolation and the mouse fix installed. The
  `dxvk.conf` is read by DXVK itself, so DLL wrappers in the game folder do
  not interfere.
- Works with any Proton or Wine setup that uses DXVK (Steam Proton, Proton GE,
  Heroic, Lutris, Bottles). It does nothing under WineD3D or on Windows.
- If you already set `DXVK_CONFIG` in your launch options, you can remove it;
  the file replaces it.
- If you only want to narrow the scope, DXVK also accepts `c` (constant
  buffers), `v` (vertex), `i` (index) and `r` (shader resources) or any
  combination, e.g. `cv`. `a` is what was tested and is the safe default.

## Upstreaming

DXVK ships per-game defaults in `src/util/config/config.cpp` and currently
has no entry for `AI.exe`. The ideal outcome is this key shipping inside DXVK
so nobody needs this repository. If you can reproduce the gain on different
hardware, please open an issue here with your numbers; that is the evidence a
DXVK pull request needs.

## License

MIT.
