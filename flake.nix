{
  description = "Flake for our infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-prev.url = "github:NixOS/nixpkgs?rev=c6245e83d836d0433170a16eb185cefe0572f8b8"; # Last working nixpkgs-unstable. Sporadically updated. Thought of doing this again.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    secrets = {
      url = "git+ssh://git@github.com/RedEtherbloom/nix0s-secrets";
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
    nix-alien.url = "github:thiagokokada/nix-alien";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        systems.follows = "systems";
        darwin.follows = ""; # Don't pull in unneeded resources
      };
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
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
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    whisp-away = {
      url = "github:madjinn/whisp-away";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jambi-transcript = {
      url = "github:guttermonk/jambi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} (
      {withSystem, ...}: {
        imports = [
          inputs.home-manager.flakeModules.home-manager
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        # TODO: Extract common resources e.g. IPs into nixos independent wrapper or import nixos into homeManager so that homeConfigurations can be split out
        flake = let
          defaultUsername = "inf";
          mkSystem = hostName: system:
            withSystem system (
              {pkgs, ...}:
                inputs.nixpkgs.lib.nixosSystem {
                  specialArgs = {
                    inherit inputs self;
                    inherit (inputs) secrets;
                  };
                  modules = [
                    {nixpkgs = {inherit (pkgs) config overlays;};}
                    # TODO: Decide how to reorganize module inputs
                    inputs.sops-nix.nixosModules.sops
                    inputs.agenix.nixosModules.default
                    inputs.nix-index-database.nixosModules.nix-index

                    ./hosts/${hostName}/configuration.nix
                  ];
                }
            );
          mkHmConfiguration = host: let
            osConfig = host.config;
            inherit (osConfig.networking) hostName;
          in
            # TODO: Move backupFileExtension to HM-Modules
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit (host) pkgs;
              # Remove potentially interferring attrs
              extraSpecialArgs =
                (removeAttrs host._module.specialArgs [
                  "self"
                  "modulesPath"
                ])
                // {
                  inherit osConfig self;
                  osFlakeSelf = osConfig._module.specialArgs.self;
                };
              modules = [
                inputs.sops-nix.homeManagerModules.sops
                inputs.agenix.homeManagerModules.default
                inputs.nix-index-database.homeModules.nix-index
                inputs.stylix.homeModules.stylix

                ./hosts/${hostName}/home.nix
                {
                  nix = {
                    inherit (osConfig.nix) package;
                    settings = {inherit (osConfig.nix.settings) substituters trusted-substituters trusted-public-keys;};
                  };

                  home = {
                    username = defaultUsername;
                    homeDirectory = osConfig.users.users."${defaultUsername}".home;
                  };
                }
              ];
            };
          # TODO: Remove system here. Should be set in hardware-configuration.nix. Alternatively: Somehow base systems packages on perSystem packages
          nixosConfigurations = {
            fractor = mkSystem "fractor" "x86_64-linux";
            neurodrive = mkSystem "neurodrive" "x86_64-linux";
            audiosink = mkSystem "audiosink" "aarch64-linux";
          };
        in {
          inherit nixosConfigurations;
          homeConfigurations = {
            "${defaultUsername}@fractor" = mkHmConfiguration nixosConfigurations.fractor;
            "${defaultUsername}@neurodrive" = mkHmConfiguration nixosConfigurations.neurodrive;
            "${defaultUsername}@audiosink" = mkHmConfiguration nixosConfigurations.audiosink;
          };
        };
        perSystem = {system, ...}: let
          # Initialize one central nixpkgs instance, including config and all required overlays
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              inputs.fenix.overlays.default
              inputs.niri-flake.overlays.niri
              inputs.emacs-overlay.overlays.default
              (import ./pkgs {inherit inputs;})
            ];
          };
        in {
          _module.args.pkgs = pkgs;
          # TODO: Check why own packages aren't exported
          legacyPackages = pkgs; # TODO: This seems wrong
          formatter = pkgs.alejandra;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              lixPackageSets.latest.lix
              alejandra
              nh
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
