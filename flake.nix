{
  description = "Flake for our infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  # TODO: Move most modules into their hosts. This is getting messy to read.
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        neurodrive = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules =
            [
              ./hosts/neurodrive/configuration.nix
              ./hosts/neurodrive/home.nix
              ./modules/desktop.nix
              ./modules/gaming.nix
              ./modules
              ./modules/development.nix
              {
                home-manager = {
                  extraSpecialArgs = {
                    inherit inputs;
                  };
                  users.inf.imports = [
                    { home.stateVersion = "24.05"; }
                    ./homeManagerModules/desktop.nix
                  ];
                };
              }
              home-manager.nixosModules.home-manager
            ]
            ++ (with nixos-hardware.nixosModules; [
              common-gpu-nvidia-nonprime
              common-hidpi
              # Xeon CPU
              common-cpu-intel-cpu-only
              common-pc
              common-pc-ssd
            ]);
        };
        fractor = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/fractor/configuration.nix
            ./modules/laptop.nix
            ./modules/gaming.nix
            ./modules
            ./modules/development.nix
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                };
                users.inf.imports = [
                  {
                    home.stateVersion = "24.05";
                  }
                  ./homeManagerModules/desktop.nix
                ];
              };
            }
            home-manager.nixosModules.home-manager
            nixos-hardware.nixosModules.lenovo-thinkpad-x230
          ];
        };
        audiosink = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./modules
            ./hosts/audiosink/configuration.nix
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                };
                users.inf.imports = [
                  { home.stateVersion = "24.05"; }
                ];
              };
            }
            home-manager.nixosModules.home-manager
            nixos-hardware.nixosModules.raspberry-pi-3
          ];
        };
      };
    };
}
