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
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    nix-comfyui,
    nix-vscode-extensions,
    ...
  } @ inputs: let
    overlay = import ./pkgs;
    specialArgs = {
      inherit inputs self;
    };
  in
    # flake-utils has mostly been copied from feas config
    flake-utils.lib.eachDefaultSystem (
      system: let
        # Still ugly tbh. E.g. allowunfree and other setting don't get applied. Maybe I should turn nixpkgs into it's own imported nix file
        pkgs = import nixpkgs {
          inherit system;
          overlays = self.overlay.defaults;
        };
        formatter = pkgs.nixfmt-rfc-style;
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            formatter
            pkgs.nil
            pkgs.nixd
            pkgs.nix-output-monitor
          ];
        };

        inherit formatter;

        packages = pkgs;
      }
    )
    // {
      overlay.defaults = [overlay nix-vscode-extensions.overlays.default nix-comfyui.overlays.default];
      # TODO: Redo with flake-parts or flake-utils once we have the spoons again
      nixosConfigurations =
        nixpkgs.lib.attrsets.genAttrs
        (nixpkgs.lib.attrsets.mapAttrsToList (name: _: name) (builtins.readDir ./hosts))
        (
          name:
            nixpkgs.lib.nixosSystem {
              inherit specialArgs;

              modules = [
                ./hosts/${name}/configuration.nix
                {
                  home-manager.users.inf.imports = [
                    ./hosts/${name}/home.nix
                  ];
                }
              ];
            }
        );
    };
}
