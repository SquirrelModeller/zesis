{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    pkgsFor = system: import nixpkgs {inherit system;};
  in {
    devShells = forEachSystem (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          quickshell
          clang-tools
        ];

        QML_IMPORT_PATH = pkgs.lib.concatStringsSep ":" [
          "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
          "${pkgs.quickshell}/lib/qt-6/qml"
        ];
      };
    });
  };
}
