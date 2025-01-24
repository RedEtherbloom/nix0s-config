{
  description = "Flake for our infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-utils.url = "github:numtide/flake-utils";

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
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    our-secrets = {
      url = "git+ssh://git@github.com/RedEtherbloom/nix0s-secrets";
      inputs = {
        nixpkgs.follows = "nixpkgs";
	home-manager.follows = "home-manager";
	sops-nix.follows = "sops-nix";
      };  
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nix-comfyui = {
      # default
      # url = "github:dyscorv/nix-comfyui";
      # pinned pr
      url = "github:haras-unicorn/nix-comfyui?rev=d62188b88aa951468bd9890be79e0b0ac5aab77c";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    raspberry-pi-nix = {
      url = "git+https://github.com/nix-community/raspberry-pi-nix?tag=v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sergv-nixos-config = {
      url = "github:sergv/nixos-config?rev=9c6306c86af6130f76d277e382c346360ec124dd";
      flake = false;
    };

    rimsort-pr = {
      url = "github:NixOS/nixpkgs?ref=pull/304943/head";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    nix-comfyui,
    nix-vscode-extensions,
    ...
  } @ inputs: let
    nixpkgsConfig = {
      overlays = [
        (import ./pkgs {inherit inputs; inherit (nixpkgs) lib;})
        nix-vscode-extensions.overlays.default
        nix-comfyui.overlays.default
      ];
      config.allowUnfree = true;
    };
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit (nixpkgsConfig) overlays config;
          inherit system;
        };
        formatter = pkgs.alejandra;
      in {
        inherit formatter;
        devShells.default = pkgs.mkShell {
          packages =
            [formatter]
            ++ (with pkgs; [
              nixd
              nix-output-monitor
              nh
            ]);
        };

        legacyPackages = pkgs;
      }
    )
    // {
      nixosConfigurations = let
        specialArgs = {
          inherit inputs self;
        };
        defaultUsername = "inf";
        # Setup common home-manager and nixpkgs options
        mkSystem = hostName: system: username:
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;

            modules = [
              inputs.home-manager.nixosModules.home-manager
              inputs.sops-nix.nixosModules.sops

              {nixpkgs = {inherit (nixpkgsConfig) overlays config;};}

              ./hosts/${hostName}/configuration.nix

              {
                home-manager = {
                  backupFileExtension = "hm_backup_move";
                  extraSpecialArgs = specialArgs;
                  useGlobalPkgs = true;
                  users.${username}.imports = [./hosts/${hostName}/home.nix];
                };
              }
            ];
          };
      in {
        fractor = mkSystem "fractor" "x86_64-linux" defaultUsername;
        neurodrive = mkSystem "neurodrive" "x86_64-linux" defaultUsername;
        audiosink = mkSystem "audiosink" "aarch64-linux" defaultUsername;
      };
    };
}
