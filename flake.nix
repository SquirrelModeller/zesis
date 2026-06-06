{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    athroisma = {
      url = "github:SquirrelModeller/athroisma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    athroisma,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    pkgsFor = system: import nixpkgs {inherit system;};
  in {
    packages = forEachSystem (system: {
      athroisma = athroisma.packages.${system}.default;
    });

    devShells = forEachSystem (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          quickshell
          clang-tools
          imagemagick
          athroisma.packages.${system}.default
        ];

        QML_IMPORT_PATH = pkgs.lib.concatStringsSep ":" [
          "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
          "${pkgs.quickshell}/lib/qt-6/qml"
        ];
      };
    });
  };
}
