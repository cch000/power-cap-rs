{
  description = "Service to limit power consumption on ryzen cpus";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs = {
    nixpkgs,
    treefmt-nix,
    self,
    ...
  }: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};

    treefmtEval = treefmt-nix.lib.evalModule pkgs {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        rustfmt.enable = true;
      };
    };

    treefmt = treefmtEval.config.build;

    buildInputs = [pkgs.pciutils];

    nativeBuildInputs = with pkgs; [
      clang
      pkg-config
      cmake
      rustPlatform.bindgenHook
    ];

    pwr-cap-rs = let
      name = "pwr-cap-rs";
    in
      pkgs.rustPlatform.buildRustPackage {
        inherit buildInputs nativeBuildInputs name;
        cargoLock.lockFile = ./Cargo.lock;
        src = ./.;
        meta.mainProgram = name;
      };
  in {
    nixosModules.pwr-cap-rs = import ./modules self;

    formatter.${system} = treefmt.wrapper;

    checks.${system}.formatting = treefmt.check self;

    devShells.${system}.default = pkgs.mkShell {
      inherit buildInputs nativeBuildInputs;
      inputsFrom = [treefmt.devShell];
      packages = with pkgs; [
        nil
        rustc
        cargo
        clippy
        rust-analyzer
      ];
    };

    packages.${system} = {
      inherit pwr-cap-rs;
      default = pwr-cap-rs;
    };
  };
}
