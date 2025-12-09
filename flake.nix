{
  description = "Flake for our infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    secrets = {
      url = "git+ssh://git@github.com/RedEtherbloom/nix0s-secrets";
      flake = false;
    };

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "github:edolstra/flake-compat";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    nvf = {
      url = "github:NotAShelf/nvf/v0.8";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
    sergv-nixos-config = {
      url = "github:sergv/nixos-config?rev=9c6306c86af6130f76d277e382c346360ec124dd";
      flake = false;
    };
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    hyprland-zaneyos = {
      url = "gitlab:Zaney/zaneyos";
      flake = false;
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprWorkspaceLayouts = {
      url = "github:zakk4223/hyprWorkspaceLayouts";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprDynamicMonitors = {
      url = "github:fiffeek/hyprdynamicmonitors";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    {
      self,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        imports = [
          inputs.home-manager.flakeModules.home-manager
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake =
          { lib, ... }:
          let
            defaultUsername = "inf";
            # TODO: Set system in configuration.nix instead, to lessen use of anti patterns
            mkSystem =
              hostName: system:
              withSystem system (
                ctx@{ ... }:
                {
                  nixosConfigurations."${hostName}" = inputs.nixpkgs.lib.nixosSystem rec {
                    specialArgs = {
                      inherit inputs self;
                      inherit (inputs) secrets;
                    };
                    modules = [
                      { nixpkgs = { inherit (ctx.pkgs) config overlays; }; }
                      # TODO: Decide how to reorganize module inputs
                      inputs.home-manager.nixosModules.home-manager
                      inputs.sops-nix.nixosModules.sops
                      inputs.nix-index-database.nixosModules.nix-index
                      ./modules/cachix.nix
                      ./hosts/${hostName}/configuration.nix
                      {
                        home-manager = {
                          backupFileExtension = "hm_backup_move";
                          extraSpecialArgs = specialArgs;
                          useGlobalPkgs = true;
                          users.${defaultUsername}.imports = [ ./hosts/${hostName}/home.nix ];
                        };
                      }
                    ];
                  };
                  # TODO: Extract common resources e.g. IPs into nixos independent wrapper or import nixos into homeManager so that homeConfigurations can be split out
                }
              );
          in
          lib.mkMerge [
            (mkSystem "fractor" "x86_64-linux")
            (mkSystem "neurodrive" "x86_64-linux")
            (mkSystem "audiosink" "aarch64-linux")
          ];
        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          rec {
            # TODO: Merge into flake-parts
            # getPatchedNixpkgs = system:
            #   (import nixpkgs {inherit system;}).applyPatches {
            #     name = "nixpkgs-patched";
            #     src = nixpkgs;
            #     patches = [];
            #   };
            # TODO: Check why own packages cannot be referred to via flake syntax
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
              };
              overlays = [
                inputs.fenix.overlays.default
                (import ./pkgs { inherit inputs; })
              ];
            };
            formatter = pkgs.alejandra;
            legacyPackages = _module.args.pkgs;
            devShells.default = pkgs.mkShell {
              buildInputs = with pkgs; [
                alejandra
                nh
                nixd
                direnv
                nix-prefetch-scripts
                nix-prefetch-github
                nix-tree
                nixos-rebuild-ng
              ];
            };
          };
      }
    );
}
