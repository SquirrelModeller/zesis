# zesis

*ζέσις - Greek for "boiling", "seething"; the act of bubbling up with heat or fervor*

A graphical shell with a mind of its own, using [Quickshell](https://quickshell.outfoxxed.me), targeting Wayland compositors.

Contributions and adaptations are welcome - the config is written to be portable across user systems rather than hardcoded to a specific machine.

---

## Architecture

### Theming
Colors live in `colors.json` and are exposed via the `Colors` singleton (`Colors.qml`). Editing `colors.json` hot-reloads the theme at runtime without restarting Quickshell. See the token list in `Colors.qml` for available palette properties.

### Compositor backend
All Hyprland-specific calls (workspace/window data, dispatch commands, monitor queries) are isolated behind a two-layer abstraction in `Widgets/Wm/`:

- **`HyprlandWmBackend`** - the only file that imports `Quickshell.Hyprland`. Exposes reactive `workspaces`, `toplevels`, and `focusedMonitor` properties, plus named action functions (`focusWorkspace`, `moveWindow`, `preselect`, etc.).
- **`WmService`** - compositor-agnostic singleton. Widgets bind to `WmService.*`. Swapping compositors means writing a new backend and changing one line: `property QtObject _backend: SwayWmBackend {}`.

The Display widget follows the same pattern with `DisplayHyprlandBackend`, and the Keybinds widget has its own `HyprlandBackend` for reading binds.

---

## Requirements

### Required
- [Quickshell](https://quickshell.outfoxxed.me) (Qt 6)
- [Matugen](https://github.com/InioX/matugen)
- A Wayland compositor that implements `wlr-layer-shell`
- A [Nerd Font](https://www.nerdfonts.com/) or the `nerd-fonts.symbols-only` package for icons
- aww (SHOULD HANDLE SINKS INSTEAD, FIX ME SQUIRREL YOU GODDAMN IDIOT)

### Optional
- Hyprland - workspace/window management, keybind cheatsheet, display picker (only backend currently implemented)
- `ext-session-lock` compositor support + PAM configuration - lock screen (see below)
- `avahi` + `smbclient` + `keyutils` - Network widget
- [athroisma](https://github.com/squirrel/athroisma) - System Monitor widget
- magick (wallpaper preview)
- awk (for credential search)

## Setup

Clone the repo and point Quickshell at it:

```sh
git clone https://github.com/squirrel/squirrel-quickshell ~/.config/quickshell
quickshell
```

### Lock screen (NixOS)

Add PAM support for the lock screen in your NixOS config:

```nix
security.pam.services.quickshell = {};
```

### Other distros

Create `/etc/pam.d/quickshell` with contents appropriate for your system (typically mirroring `login` or `swaylock`).

## Development

A Nix flake is included with a devshell that provides Quickshell and `clangd` with the correct `QML_IMPORT_PATH`:

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

This is a personal config, but PRs and issues are welcome - especially for portability improvements.
