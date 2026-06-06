# squirrel-quickshell

A personal [Quickshell](https://quickshell.outfoxxed.me) configuration written in QML, targeting Wayland compositors (primarily Hyprland).

Contributions and adaptations are welcome, the config is written to be portable across user systems rather than hardcoded to a specific machine.

## Theming

Colors live in `colors.json` and are exposed via the `Colors` singleton (`Colors.qml`). Editing `colors.json` hot-reloads the theme at runtime without restarting Quickshell. See the token list in `Colors.qml` for available palette properties.

## Requirements

- [Quickshell](https://quickshell.outfoxxed.me) (Qt 6)
- A Wayland compositor that implements `wlr-layer-shell` and `ext-session-lock`
- A [Nerd Font](https://www.nerdfonts.com/) or the `nerd-fonts.symbols-only` package for icons throughout the shell
- PAM configuration for the lock screen (see below)

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

`.qmlls.ini` is gitignored, its content is machine-specific.

#### VSCode / VSCodium

Enable `qt-qml.qmlls.useQmlImportPathEnvVar` in your workspace settings so `qmlls` picks up `QML_IMPORT_PATH` from the devshell. `.vscode/` is gitignored; manage your own local workspace settings.

## Contributing

This is a personal config, but PRs and issues are welcome - especially for portability improvements.

Commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
feat: add notification grouping
fix: correct workspace indicator z-order
chore: update flake inputs
```
