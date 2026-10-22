# TODO: Add checks and add deploy-rs to devShell
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        flake-parts.follows = "flake-parts";
        import-tree.follows = "import-tree";
        sops-nix.follows = "sops-nix";
      };
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    systems.url = "github:nix-systems/default";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };

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
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs-fix-openrazer-pr = {
      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/576293.patch";
      flake = false;
    };
    nixpkgs-fix-pyopenjtalk-pr = {
      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/576063.patch";
      flake = false;
    };
    nixpkgs-fix-openwebui-pr = {
      url = "https://github.com/NixOS/nixpkgs/pull/576653.patch";
      flake = false;
    };
    nixpkgs-fix-audacity-pr = {
      url = "https://github.com/NixOS/nixpkgs/pull/577022.patch";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      {
        withSystem,
        self,
        ...
      }: {
        imports = [
          inputs.flake-parts.flakeModules.modules
          inputs.home-manager.flakeModules.home-manager
          (inputs.import-tree.matchNot ".*/hardware-configuration.nix" [
            ./dendriticModules
            ./hosts
          ])
        ];
        debug = true;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake = {
          nixosConfigurations = let
            mkSystem = hostname: system:
              withSystem system (
                {pkgs, ...}:
                  inputs.nixpkgs.lib.nixosSystem {
                    specialArgs = {
                      inherit inputs self;
                      inherit (inputs) home-manager secrets;
                    };
                    modules = [
                      {nixpkgs.pkgs = pkgs;}
                      self.nixosModules.${hostname}
                    ];
                  }
              );
          in {
            fractor = mkSystem "fractor" "x86_64-linux";
            neurodrive = mkSystem "neurodrive" "x86_64-linux";
            audiosink = mkSystem "audiosink" "aarch64-linux";
          };
          deploy.nodes = withSystem "x86_64-linux" (
            {pkgs, ...}: {
              fractor = {
                hostname = "fractor.tail83ad26.ts.net";
                profiles.system = {
                  user = "root";
                  path = pkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.fractor;
                };
              };
              neurodrive = {
                hostname = "neurodrive.tail83ad26.ts.net";
                profiles.system = {
                  user = "root";
                  path = pkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.neurodrive;
                };
              };
              audiosink = {
                hostname = "audiosink.tail83ad26.ts.net"; # TODO: Connect to tailscale
                profiles.system = {
                  user = "root";
                  path = pkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.audiosink;
                };
              };
            }
          );
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
          _module.args.pkgs = let
            nixpkgs-patched = (import inputs.nixpkgs {inherit config system;}).applyPatches {
              name = "nixpkgs-patched";
              src = inputs.nixpkgs;
              patches = [inputs.nixpkgs-fix-openrazer-pr inputs.nixpkgs-fix-pyopenjtalk-pr inputs.nixpkgs-fix-openwebui-pr inputs.nixpkgs-fix-audacity-pr];
            };
          in
            import nixpkgs-patched {
              inherit config system;
              overlays = [
                (_: prev: {
                  _deploy-rs-original = prev.deploy-rs;
                })
                # NOTE: Not entirely sure if this overrides the deploy-rs set in the activate functions
                inputs.deploy-rs.overlays.default
                (final: prev: {
                  deploy-rs = {
                    deploy-rs = prev._deploy-rs-original;
                    lib = prev.deploy-rs.lib;
                  };
                })
                (final: prev: {
                  nixpkgs-unstable-small = import inputs.nixpkgs-unstable-small {inherit system config;};
                })
                self.overlays.default
              ];
            };
          formatter = pkgs.alejandra;
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.lixPackageSets.latest.lix
              pkgs.lixPackageSets.latest.nixos-rebuild-ng
              pkgs.lixPackageSets.latest.nix-direnv
              pkgs.lixPackageSets.latest.nix-init
              pkgs.lixPackageSets.latest.nurl
              pkgs.lixPackageSets.latest.nix-update
              pkgs.lixPackageSets.latest.colmena
              pkgs.lixPackageSets.latest.nix-du
              pkgs.pre-commit
              pkgs.alejandra
              pkgs.nh
              pkgs.nix-tree
              pkgs.deploy-rs.deploy-rs
            ];
          };
          # checks = builtins.mapAttrs (system: deployLib: (pkgs.lib.debug.trace self deployLib.deployChecks) (pkgs.lib.debug.trace self self.deploy)) pkgs.deploy-rs.lib;
          checks = pkgs.deploy-rs.lib.deployChecks self.deploy;
        };
      }
    );
}
