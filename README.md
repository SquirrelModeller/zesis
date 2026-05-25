# Quickshell

The code here is mostly for testing, in development. So there are a lot of questionable lines of code.

This folder has been copy and pasted to nixos from my previous setup. I have not looked into quickshell on NixOS yet.

## Editor setup

### QML language server

Create an empty `.qmlls.ini` file next to `shell.qml`. Quickshell will populate it with a managed qmlls configuration on first run.

`.qmlls.ini` is gitignored as its content is machine-specific.

### VSCode / VSCodium

Enable `qt-qml.qmlls.useQmlImportPathEnvVar` in your settings so qmlls picks up `QML_IMPORT_PATH` from the project devshell.

`.vscode/` is gitignored — manage your own local workspace settings.
