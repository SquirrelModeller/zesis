<h1 align="center">zesis</h1>

<p align="center"><em>ζέσις - Greek for "boiling", "seething": the act of bubbling up with heat or fervor</em></p>

<div align="center">

[![Discord](https://img.shields.io/badge/discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=ffffff&labelColor=101418)](https://discord.gg/npWCSGaju7)

</div>

<!-- TODO: drop a screenshot/short video -->

zesis is a desktop shell for Wayland. A bar plus a full suite of panels and widgets all written in QML on top of [Quickshell](https://quickshell.outfoxxed.me) and themed live via [Matugen](https://github.com/InioX/matugen).

It's built for **Hyprland**, that's the only compositor backend implemented so far, on any Wayland compositor that supports `wlr-layer-shell` in principle. The config is written to be portable across machines.

> [!NOTE]
> Running into a bug, missing something you'd like to see, or just have a question? Please [open an issue](https://github.com/zesis-shell/zesis/issues) - you are very welcome to. Alternatively, reach out on [Discord](https://discord.gg/npWCSGaju7) or at zesis-shell@protonmail.com.

## What's in it

- **Bar** - workspace indicator, system tray, clock, music, and more, with automatic collision-based collapsing
- **App switcher** - Alt-Tab style, mouse and keyboard aware
- **Lock screen** - PAM-backed, with a clock and user greeting
- **Home panel** - a settings-app-style shell hub (Calendar, Network, System Monitor, Community, NixOS purity checker, notification history)
- **Notifications**, **keybind cheatsheet**, **display picker**, **network (SMB) browser**, **weather**, **Bluetooth + AirPods**, **volume/mic/brightness controls**, **wallpaper picker**
- **Community globe** - a live 2D/3D globe widget for opt-in location sharing
- **Desktop widgets** - toggle floating widgets directly onto your desktop, with drag-to-position, resize, and per-widget background styling
- **Theming** - hot-reloadable color palette via a `Colors` singleton, generated from your wallpaper by Matugen

## Components

- Widgets: [Quickshell](https://quickshell.outfoxxed.me)
- Compositor: [Hyprland](https://hyprland.org) (only backend currently implemented)
- Theming: [Matugen](https://github.com/InioX/matugen)

---

## Requirements

### Required

> [!TIP]
> On Arch, the fastest path is:
> ```sh
> sudo pacman -S quickshell matugen nerd-fonts.symbols-only
> ```

- [Quickshell](https://quickshell.outfoxxed.me) (Qt 6)
- [Matugen](https://github.com/InioX/matugen)
- A Wayland compositor that implements `wlr-layer-shell`, in practice **Hyprland**, since it's the only compositor backend written so far.
- A [Nerd Font](https://www.nerdfonts.com/) or the `nerd-fonts.symbols-only` package for icons.
- One wallpaper-setting backend: [awww](https://codeberg.org/LGFae/awww) (default), [swww](https://codeberg.org/LGFae/awww), `hyprpaper`, `feh`, or a custom command, configurable in the Wallpaper settings panel.
- `bash`, `curl`, `python3` - widgets shell out to these directly for core features: theming, weather, AirPods, the 3D globe's starfield generation.
- A handful of standard desktop utilities most Linux systems already have: `bluez` (`bluetoothctl`, for Bluetooth/AirPods), `libnotify` (`notify-send`), `brightnessctl`, `slurp`, `xdg-utils` (`xdg-open`), `procps` (`pkill`, `pgrep`), `gawk`, `hostname`. On NixOS, the [NixOS module](#nixos-module)'s `services.zesis.batteriesIncluded.enable = true;` puts all of these on the service's `PATH` for you, if you don't already have them.

### Optional

Nothing below is required to get a working bar, each of these lights up one extra widget and degrades with an on-screen message if missing.

| Needs | Unlocks |
| --- | --- |
| `ext-session-lock` support + PAM config | Lock screen ([see below](#lock-screen)) |
| `avahi` + `smbclient` + `keyutils` | Network widget |
| [athroisma](https://github.com/zesis-shell/athroisma) | System Monitor widget ([see below](#system-monitor-athroisma)) |
| [`icalendar`](https://pypi.org/project/icalendar/) + [`recurring-ical-events`](https://pypi.org/project/recurring-ical-events/) (python3 packages) | Calendar widget (`.ics` files, including recurring events) |
| `magick` | Wallpaper thumbnail previews |
| QtQuick3D + QtDeclarative (Qt 6.6+) + [Congeries](https://github.com/zesis-shell/congeries) | 3D geodesic rod globe (Home panel) ([see below](#3d-globe-congeries)) |

## Setup

> [!TIP]
> On NixOS, skip straight to the [NixOS module](#nixos-module) below, it handles the clone, shader compilation, and the athroisma/congeries wiring in one `services.zesis.enable = true;`.

> [!WARNING]
> This clones straight into `~/.config/quickshell`. If you already have something there, back it up first.

```sh
git clone https://github.com/zesis-shell/zesis ~/.config/quickshell
quickshell
```

That starts zesis in the foreground, you should see the bar appear on your primary monitor immediately. To launch it automatically on login, add it to your Hyprland config:

```conf
exec-once = quickshell
```

### NixOS module

The flake exposes `nixosModules.default`, which builds zesis (source + compiled shaders) and deploys it as a *named* Quickshell config (`zesis`), wired into a `systemd --user` service. This covers the whole optional-dependency nonsense above automatically. Shaders are compiled at build time, `athroisma` is put on the service's `PATH`, and `congeries` is put on its `QML_IMPORT_PATH`.

```nix
{
  inputs.zesis.url = "github:zesis-shell/zesis";

  outputs = {nixpkgs, zesis, ...}: {
    nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
      modules = [
        zesis.nixosModules.default
        {services.zesis.enable = true;}
      ];
    };
  };
}
```

Zesis puts the built config at `/etc/xdg/quickshell/zesis`, and starts a `zesis.service` wanted by `graphical-session.target`.

Both optional deps can be turned off or repointed per-widget:

```nix
services.zesis = {
  enable = true;
  athroisma.enable = false; # or: athroisma.package = ...;
  congeries.enable = false; # or: congeries.package = ...;
};
```

Beyond athroisma/congeries, plenty of widgets shell out to ordinary desktop tools - matugen, awww, bluetoothctl, curl, notify-send, and so on. By default the service just inherits your normal desktop `PATH` (system-wide installs plus your own per-user profile) for those, so if your system already has them, there's nothing to do. If it doesn't, like a minimal box, or you just want zesis working with zero prior setup, then set `services.zesis.batteriesIncluded.enable = true;` to put the whole set on the service's `PATH` outright:

```nix
services.zesis = {
  enable = true;
  batteriesIncluded.enable = true; # or: batteriesIncluded.packages = [...];
};
```

If you'd rather the service *not* inherit your desktop `PATH` at all, an explicit, reproducible dependency surface instead of whatever happens to be installed, or just tighter isolation, then set `services.zesis.inheritPath = false;`. You'll almost certainly want `batteriesIncluded.enable = true;` alongside it:

```nix
services.zesis = {
  enable = true;
  inheritPath = false;
  batteriesIncluded.enable = true; # or: batteriesIncluded.packages = [...];
};
```

> [!IMPORTANT]
> Because this is a *named* config, any manual `quickshell`/`qs` invocation, IPC calls in your compositor keybinds, `hypridle.conf`, debugging, etc., needs `-c zesis` (or `QS_CONFIG_NAME=zesis`) or it won't find this instance. See [IPC dispatch](#ipc-dispatch) below.

The module doesn't set up the [lock screen's PAM service](#lock-screen), that's still a separate step.

If you'd rather launch zesis yourself, e.g. with `exec-once = quickshell -c zesis` in your compositor config, instead of the `systemd --user` service, set `services.zesis.systemdService.enable = false;`. The config still lands at `/etc/xdg/quickshell/zesis` either way, only the service is skipped. Note this also skips the service's automatic `athroisma` `PATH` and `congeries` `QML_IMPORT_PATH` wiring, so an `exec-once` launch needs those set up wherever you invoke `quickshell` from (your compositor config's own environment, a wrapper script, etc.) if you use those optional deps.

### Keybinds

zesis doesn't ship any default keybinds. App switcher, home panel, keybind cheatsheet, lock screen, and everything else are triggered by IPC calls (see [IPC dispatch](#ipc-dispatch)) that you wire up yourself in your compositor config.

For a complete working example, see this author's own [Hyprland config](https://github.com/SquirrelModeller/squirrel-nixos/blob/main/users/squirrel/dotfiles/.config/hypr/hyprland.lua).

The keybind cheatsheet widget reads binds straight from `hyprctl binds -j`, so any bind with a description formatted as `"Category: Label"` shows up there automatically.

### Lock screen

Add PAM support for the lock screen.

**NixOS:**

```nix
security.pam.services.quickshell = {};
```

**Other distros:** create `/etc/pam.d/quickshell` with contents appropriate for your system (typically mirroring `login` or `swaylock`).

### Compiling shaders

`ShaderEffect`-based widgets (currently the 2D globe) load a pre-baked `.qsb` binary, not the `.frag` source directly. `*.qsb` files are gitignored build artifacts, so they need to be compiled locally before those widgets will render. If a `.qsb` is missing or invalid, the affected widget just shows an on-screen warning.

On NixOS via the [NixOS module](#nixos-module), shaders are already compiled as part of `services.zesis.configPackage`, nothing to do here.

With Nix otherwise:

```sh
nix run .#compile-shaders
```

Without Nix, `qsb` comes from Qt's `qtshadertools` module, on most distros this is a separate package from Qt/Quickshell itself and often isn't pulled in automatically (e.g. on Arch, `qt6-shadertools` is only a *build-time* dependency of the `quickshell` package, not a runtime one), so you may need to install it explicitly:

```sh
# Arch
sudo pacman -S qt6-shadertools
```

Then compile every `.frag` file under `Widgets/` to a matching `.qsb`:

```sh
find Widgets -name '*.frag' -exec sh -c 'qsb --qt6 -o "${1%.frag}.qsb" "$1"' _ {} \;
```

### System monitor (athroisma)

The System Monitor widget shells out to a bare `athroisma` command, so it needs to be on `PATH`, it's otherwise entirely optional, the rest of zesis is unaffected if it's missing.

On NixOS via the [NixOS module](#nixos-module), `services.zesis.athroisma.enable` is on by default and already puts it on the service's `PATH`.

With Nix otherwise, `flake.nix` declares `athroisma` as a flake input and puts it on the devshell's `PATH`.

Arch users can install it from the AUR instead: [`athroisma-git`](https://aur.archlinux.org/packages/athroisma-git).

Otherwise, it's a small Rust binary, build it with Cargo and put the result on `PATH`:

```sh
git clone https://github.com/zesis-shell/athroisma
cd athroisma
cargo build --release
install -Dm755 target/release/athroisma ~/.local/bin/athroisma
```

Make sure `~/.local/bin` (or wherever you installed it) is on `PATH` for whatever launches zesis.

### 3D globe (Congeries)

The Home panel's 3D geodesic rod globe needs [Congeries](https://github.com/zesis-shell/congeries), a native QtQuick3D plugin from a sibling repo. It's entirely optional, if it's missing, that panel just shows a "3D globe unavailable" message instead of failing.

On NixOS via the [NixOS module](#nixos-module), `services.zesis.congeries.enable` is on by default and already wires it into the service's `QML_IMPORT_PATH`.

With Nix otherwise, `flake.nix` declares `congeries` as a flake input and wires it into the devshell's `QML_IMPORT_PATH`/`QT_PLUGIN_PATH`.

Without Nix, build it manually with CMake and add the result to `QML_IMPORT_PATH`:

```sh
git clone https://github.com/zesis-shell/congeries
cd congeries
cmake -B build -G Ninja
cmake --build build
cmake --install build --prefix ~/.local

export QML_IMPORT_PATH="$HOME/.local/lib/qt-6/qml:$QML_IMPORT_PATH"
```

Dependencies: Qt 6.6+ (`Core`, `Qml`, `Quick3D`) and `libpipewire-0.3`. See Congeries' own README for details.

---

## Architecture

*The rest of this section is for contributors and the curious, skip it if you just want zesis running.*

### Theming
Colors live in `colors.json` and are exposed via the `Colors` singleton (`Colors.qml`). Editing `colors.json` hot-reloads the theme at runtime without restarting Quickshell. See the token list in `Colors.qml` for available palette properties.

### Compositor backend
All Hyprland-specific calls (workspace/window data, dispatch commands, monitor queries) are isolated behind a two-layer abstraction in `Widgets/Wm/`:

- **`HyprlandWmBackend`** - the only file that imports `Quickshell.Hyprland`. Exposes reactive `workspaces`, `toplevels`, and `focusedMonitor` properties, plus named action functions (`focusWorkspace`, `moveWindow`, `preselect`, etc.).
- **`WmService`** - compositor-agnostic singleton. Widgets bind to `WmService.*`. Swapping compositors means writing a new backend and changing one line: `property QtObject _backend: SwayWmBackend {}`.

The Display widget follows the same pattern with `DisplayHyprlandBackend`, and the Keybinds widget has its own `HyprlandBackend` for reading binds.

### IPC dispatch

Compositor keybinds trigger shell actions through Quickshell's `IpcHandler`. Each overlay/panel exposes its own `IpcHandler { target: "..." }` block with named functions that flip the relevant service's state:

| Target | Function(s) | Defined in |
| --- | --- | --- |
| `keybinds` | `toggle()` | `shell.qml` |
| `home` | `toggle()` | `shell.qml` |
| `settings` | `toggle()` | `shell.qml` |
| `appswitcher` | `cycle()`, `back()`, `confirm()`, `cancel()` | `shell.qml` |
| `desktop` | `toggleConfig()` | `shell.qml` |
| `power` | `toggle()` | `shell.qml` |
| `lockscreen` | `lock()`, `unlock()` | `Widgets/LockScreen/LockScreen.qml` |

Since Quickshell instances are identified by config path, a dev instance launched with `qs -p ~/Documents/zesis` won't receive `qs ipc call` from a plain install pointed at `~/.config/quickshell` (or vice versa), the compositor config resolves this by trying the dev path first and falling back. Example from this author's own [Hyprland config](https://github.com/SquirrelModeller/squirrel-nixos/blob/main/users/squirrel/dotfiles/.config/hypr/hyprland.lua):

```lua
-- Hyprland
local ZESIS_DEV = os.getenv("HOME") .. "/Documents/zesis"
local function zesis_ipc(cmd)
    return string.format("sh -c 'qs -p %s ipc call %s 2>/dev/null || qs ipc call %s'", ZESIS_DEV, cmd, cmd)
end
hl.bind("ALT + Tab", hl.dsp.exec_cmd(zesis_ipc("appswitcher cycle")), { repeating = true })
```

### Display

Most compositors only apply monitor config at their own startup, so a backend's job is more than read/apply, the picked mode also has to survive a compositor restart.

The compositor config is expected to read a cache file back at its own startup and fall back to a hardcoded default if it's missing. `DisplayHyprlandBackend` is the only backend implemented so far.

```lua
local _d_ok, _d = pcall(dofile, os.getenv("HOME") .. "/.cache/zesis/display.lua")
local d = _d_ok and _d or {}
hl.monitor({
    output   = d.output or "DP-1",
    mode     = d.mode or "preferred",
})
```

## Development

A Nix flake is included with a devshell that provides Quickshell with the correct `QML_IMPORT_PATH`:

```sh
nix develop
```

An `.envrc` is included for [direnv](https://direnv.net/) users - `direnv allow` will drop you into the devshell automatically on `cd`.

This makes `qmlls` and `clangd` aware of Quickshell's QML modules for IDE completions and type checking.

### Editor setup

Create an empty `.qmlls.ini` file next to `shell.qml`. Quickshell populates it with a managed `qmlls` configuration on first run.

```sh
touch .qmlls.ini
```

`.qmlls.ini` is gitignored - its content is machine-specific.

#### VSCode / VSCodium

Enable `qt-qml.qmlls.useQmlImportPathEnvVar` in your workspace settings so `qmlls` picks up `QML_IMPORT_PATH` from the devshell. `.vscode/` is gitignored; manage your own local workspace settings.

## Contributing

PRs and issues are welcome - especially for portability improvements (new compositor backends, distro packaging, etc).

## License

Zesis is licensed under the [GNU General Public License v3.0](LICENSE) or later.
