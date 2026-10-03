#!/usr/bin/env bash
# Alien: Isolation Linux FPS fix — installer
# Writes "d3d11.cachedDynamicResources = a" into a dxvk.conf next to AI.exe.
# https://github.com/sidnei-almeida/alien-isolation-linux-fix
set -euo pipefail

KEY="d3d11.cachedDynamicResources"
VALUE="a"
MARK="# alien-isolation-linux-fix"
EXE="AI.exe"

DRY_RUN=0
UNINSTALL=0
declare -a PATHS=()

usage() {
  cat <<USAGE
Usage: $0 [--path <game dir>]... [--uninstall] [--dry-run]

  --path DIR     Game folder containing $EXE (can be given more than once).
                 Without it, Steam libraries and common launcher paths are searched.
  --uninstall    Remove the fix from dxvk.conf.
  --dry-run      Show what would be done without changing anything.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) shift; [[ $# -gt 0 ]] || { usage; exit 2; }; PATHS+=("$1") ;;
    --uninstall) UNINSTALL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

log()  { printf '  %s\n' "$*"; }
ok()   { printf '\033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
err()  { printf '\033[31m✘\033[0m %s\n' "$*" >&2; }

# --- locate the game -------------------------------------------------------

steam_roots() {
  local r
  for r in \
    "$HOME/.local/share/Steam" \
    "$HOME/.steam/root" \
    "$HOME/.steam/steam" \
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" \
    "$HOME/snap/steam/common/.local/share/Steam"; do
    [[ -d "$r/steamapps" ]] && readlink -f "$r"
  done | sort -u
}

steam_libraries() {
  local root vdf
  for root in $(steam_roots); do
    echo "$root"
    vdf="$root/steamapps/libraryfolders.vdf"
    [[ -f "$vdf" ]] || continue
    # lines like:    "path"    "/mnt/games/SteamLibrary"
    sed -nE 's/^[[:space:]]*"path"[[:space:]]+"([^"]+)".*$/\1/p' "$vdf" | sed 's#\\\\#/#g'
  done | sort -u
}

find_game() {
  local lib d
  for lib in $(steam_libraries); do
    d="$lib/steamapps/common/Alien Isolation"
    [[ -f "$d/$EXE" ]] && echo "$d"
  done
  # Heroic / Lutris / Bottles / manual installs: shallow search in common roots
  local root
  for root in "$HOME/Games" "$HOME/.local/share/lutris" "$HOME/.var/app/com.heroicgameslauncher.hgl" \
              "$HOME/.var/app/net.lutris.Lutris" "$HOME/.local/share/bottles" "$HOME/.var/app/com.usebottles.bottles"; do
    [[ -d "$root" ]] || continue
    find -L "$root" -maxdepth 6 -type f -name "$EXE" -printf '%h\n' 2>/dev/null || true
  done
}

# canonical paths, so a symlinked copy of the folder is handled once
canon() { while IFS= read -r p; do readlink -f -- "$p"; done; }

if [[ ${#PATHS[@]} -eq 0 ]]; then
  mapfile -t PATHS < <(find_game | canon | sort -u)
fi

if [[ ${#PATHS[@]} -eq 0 ]]; then
  err "Could not find $EXE. Pass the game folder explicitly:"
  log "$0 --path \"/path/to/Alien Isolation\""
  exit 1
fi

# --- apply / remove --------------------------------------------------------

apply_fix() {
  local dir="$1" conf="$1/dxvk.conf"
  if [[ -f "$conf" ]] && grep -qE "^[[:space:]]*$KEY[[:space:]]*=[[:space:]]*$VALUE[[:space:]]*$" "$conf"; then
    ok "Already installed: $conf"
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] would write '$KEY = $VALUE' to $conf"
    return
  fi
  if [[ -f "$conf" ]]; then
    [[ -f "$conf.bak" ]] || cp -p "$conf" "$conf.bak"
    if grep -qE "^[[:space:]]*#?[[:space:]]*$KEY[[:space:]]*=" "$conf"; then
      # replace any existing (possibly commented) line for this key
      sed -i -E "s|^[[:space:]]*#?[[:space:]]*$KEY[[:space:]]*=.*$|$KEY = $VALUE|" "$conf"
    else
      printf '\n%s\n%s = %s\n' "$MARK" "$KEY" "$VALUE" >> "$conf"
    fi
    ok "Updated $conf (backup at dxvk.conf.bak)"
  else
    printf '%s\n%s = %s\n' "$MARK" "$KEY" "$VALUE" > "$conf"
    ok "Created $conf"
  fi
}

remove_fix() {
  local dir="$1" conf="$1/dxvk.conf"
  if [[ ! -f "$conf" ]]; then
    warn "Nothing to remove in $dir"
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] would remove '$KEY' lines from $conf"
    return
  fi
  sed -i -E "/^[[:space:]]*$KEY[[:space:]]*=.*$/d; /^$(printf '%s' "$MARK" | sed 's/[][\\.*^$/]/\\&/g')[[:space:]]*$/d" "$conf"
  if [[ ! -s "$conf" ]] || ! grep -qvE '^[[:space:]]*$' "$conf"; then
    rm -f "$conf"
    ok "Removed $conf"
  else
    ok "Removed the fix from $conf (other settings kept)"
  fi
}

for dir in "${PATHS[@]}"; do
  if [[ ! -f "$dir/$EXE" ]]; then
    err "$EXE not found in: $dir"
    continue
  fi
  echo "Game found: $dir"
  if [[ $UNINSTALL -eq 1 ]]; then remove_fix "$dir"; else apply_fix "$dir"; fi
done

if [[ $UNINSTALL -eq 0 && $DRY_RUN -eq 0 ]]; then
  echo
  log "Restart the game for the change to take effect."
  log "No launch options are needed; DXVK reads dxvk.conf from the game folder."
fi
