{
  description = "NixOS configuration";

  # All inputs for the system
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} ({...}: {

      flake.nixosModules = {
        pwr-cap-rs = import ./modules/pwr-cap-rs.nix;
      };

      systems = ["x86_64-linux"];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = {
        config,
        pkgs,
        lib,
        ...
      }: let
        buildInputs = [pkgs.pciutils];

        nativeBuildInputs = with pkgs; [
          clang
          pkg-config
          cmake
          rustPlatform.bindgenHook
        ];

        pwr-cap-rs = pkgs.rustPlatform.buildRustPackage rec {
          inherit buildInputs nativeBuildInputs;
          name = "pwr-cap-rs";
          cargoLock.lockFile = ./Cargo.lock;
          src = ./.;

          meta = {
            maintainers = with lib.maintainers; [cch000];
            mainProgram = name;
            platforms = ["x86_64-linux"];
            license = lib.licenses.gpl3Plus;
          };
        };
      in {
        treefmt.config = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            rustfmt.enable = true;
          };
        };
        devShells.default = pkgs.mkShell {
          inherit buildInputs nativeBuildInputs;

          inputsFrom = [config.treefmt.build.devShell];

          packages = with pkgs; [
            nil
            rustc
            cargo
            rust-analyzer
          ];
        };

        packages.default = pwr-cap-rs;
      };
    });
}
