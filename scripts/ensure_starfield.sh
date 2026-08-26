#!/usr/bin/env bash
# One-shot: make sure widgets/globe3d/RealStarField.js exists before
# quickshell parses AssemblyGlobeView.qml's static `import "RealStarField.js"`
#
# On a manual (non-Nix) install, $repo_root is a writable directory, so we
# generate into a per-user cache and symlink it into place ourselves, same
# as always.
#
# Under the Nix module, the deployed config tree is read-only (it's a
# symlink into the Nix store), so $target can't be created here. Instead
# flake.nix's `config` package pre-declares it as a symlink to the shared
# cache path below (starfield data is identical for every user, no reason to
# duplicate the ~34MB catalog per-user). We just need to populate that path.
# The already-existing symlink starts resolving on its own once we do.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$repo_root/widgets/globe3d/RealStarField.js"

if [ -e "$target" ]; then
    exit 0
fi

shared_cache="/var/cache/zesis/starfield"
user_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zesis/starfield"

if mkdir -p "$shared_cache" 2>/dev/null && [ -w "$shared_cache" ]; then
    cache_dir="$shared_cache"
else
    cache_dir="$user_cache"
    mkdir -p "$cache_dir"
fi

csv="$cache_dir/hygdata_v41.csv"
js="$cache_dir/RealStarField.js"

# Lock to a commit, which we know is not comprimised upstream
catalog_commit="3bf37f4b2d5460e1278286320d1d62fab9b493c1"
catalog_sha256="d9f69fd86bbf90a4e4d52b4c5c53eacfa6dfc0bfdef85bfd94f095e0bebe4ebd"

if [ ! -e "$js" ]; then
    if [ ! -e "$csv" ]; then
        echo "ensure_starfield: downloading HYG catalog (one-time, ~34MB)..." >&2
        curl -sL "https://raw.githubusercontent.com/astronexus/HYG-Database/$catalog_commit/hyg/CURRENT/hygdata_v41.csv" -o "$csv.tmp"
        echo "$catalog_sha256  $csv.tmp" | sha256sum -c - >&2
        mv "$csv.tmp" "$csv"
    fi
    echo "ensure_starfield: generating RealStarField.js..." >&2
    python3 "$repo_root/scripts/build_starfield.py" "$csv" "$js"
fi

# In the shared-cache case $target is already a Nix-declared symlink to $js.
# Nothing left to do once $js exists. Otherwise (manual install) create it.
if [ ! -L "$target" ]; then
    ln -sf "$js" "$target"
fi
