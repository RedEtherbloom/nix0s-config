{
  description = "Flake for our infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    import-tree.url = "github:vic/import-tree";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    secrets = {
      url = "git+ssh://git@github.com/RedEtherbloom/nix0s-secrets";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    systems.url = "github:nix-systems/default";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien.url = "github:thiagokokada/nix-alien";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {
        withSystem,
        self,
        ...
      }: {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake.nixosConfigurations = let
          mkSystem = hostName: system:
            withSystem system (
              {pkgs, ...}:
                inputs.nixpkgs.lib.nixosSystem {
                  specialArgs = {
                    inherit inputs self;
                    inherit (inputs) home-manager secrets;
                  };
                  modules = [
                    inputs.nixpkgs.nixosModules.readOnlyPkgs
                    {nixpkgs.pkgs = pkgs;}
                    {stylix.overlays.enable = false;}
                    ./hosts/${hostName}/configuration.nix
                  ];
                }
            );
        in {
          fractor = mkSystem "fractor" "x86_64-linux";
          neurodrive = mkSystem "neurodrive" "x86_64-linux";
          audiosink = mkSystem "audiosink" "aarch64-linux";
        };
        perSystem = {
          pkgs,
          system,
          ...
        }: let
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "olm-3.2.16" # Required by Nheko to work
              "electron-39.8.10" # Bitwarden
            ];
          };
        in {
          # Initialize one central nixpkgs instance, including config and all required overlays
          _module.args.pkgs = import inputs.nixpkgs {
            inherit config system;
            overlays = [
              inputs.niri-flake.overlays.niri
              inputs.emacs-overlay.overlays.default
              (final: prev: {
                nixpkgs-unstable-small = import inputs.nixpkgs-unstable-small {inherit system config;};
              })
              (import ./pkgs {inherit inputs;})
            ];
            # patches = [ ];
          };
          formatter = pkgs.alejandra;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs.lixPackageSets.latest;
              [
                lix
                nixos-rebuild-ng
                nix-direnv
                nix-init
                nurl
                nix-update
                colmena
                nix-du
              ]
              ++ (with pkgs; [
                pre-commit
                alejandra
                nh
                nix-tree
              ]);
          };
        };
      }
    );
}
