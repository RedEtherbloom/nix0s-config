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
      url = "github:RedEtherbloom/home-manager?rev=3c057e67fbd9eabd979813bf55424a0d22bb9a0c";
      #url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
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
      url = "github:RedEtherbloom/nix0s-secrets";
      inputs = {
        nixpkgs.follows = "nixpkgs";
	home-manager.follows = "home-manager";
	sops-nix.follows = "sops-nix";
      };  
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      ...
    }@inputs:
    let
      overlay = import ./pkgs;
      specialArgs = {
        inherit inputs self;
      };
    in
    # flake-utils has mostly been copied from feas config
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Still ugly tbh. E.g. allowunfree and other setting don't get applied. Maybe I should turn nixpkgs into it's own imported nix file
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
        formatter = pkgs.nixfmt-rfc-style;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            formatter
            pkgs.nil
            pkgs.nixd
            pkgs.nix-output-monitor
          ];
        };

        inherit formatter;
      }
    )
    // {
      overlay.defaults = [ overlay ];
      # TODO: Can I change this with libGenAttrs?
      nixosConfigurations = {
        neurodrive = nixpkgs.lib.nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = [
            ./hosts/neurodrive/configuration.nix
            {
              home-manager = {
                users.inf.imports = [
                  ./hosts/neurodrive/home.nix
                ];
              };
            }
          ];
        };
        fractor = nixpkgs.lib.nixosSystem {
          inherit specialArgs;

          system = "x86_64-linux";
          modules = [
            ./hosts/fractor/configuration.nix
            {
              home-manager = {
                users.inf.imports = [
                  ./hosts/fractor/home.nix
                ];
              };
            }
          ];
        };
        audiosink = nixpkgs.lib.nixosSystem {
          inherit specialArgs;

          system = "aarch64-linux";
          modules = [
            ./hosts/audiosink/configuration.nix
            {
              home-manager = {
                users.inf.imports = [
                  ./hosts/audiosink/home.nix
                ];
              };
            }
          ];
        };
      };
    };
}
