{
  description = "Flake for our infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      homeManagerOptions = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        # TODO: Figure out how to set extraSpecialArgs for all hosts
      };
    in
    {
      nixosConfigurations = {
        neurodrive = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs homeManagerOptions;
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
                    inherit inputs homeManagerOptions;
                  };
                  users.inf.imports = [
                    { home.stateVersion = "24.05"; }
                    ./homeManagerModules/desktop.nix
                  ];
                };
              }
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
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
            inherit inputs homeManagerOptions;
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
                  inherit inputs homeManagerOptions;
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
            sops-nix.nixosModules.sops
            nixos-hardware.nixosModules.lenovo-thinkpad-x230
          ];
        };
        audiosink = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs homeManagerOptions;
          };
          modules = [
            ./modules
            ./hosts/audiosink/configuration.nix
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs homeManagerOptions;
                };
                users.inf.imports = [
                  { home.stateVersion = "24.05"; }
                ];
              };
            }
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nixos-hardware.nixosModules.raspberry-pi-3
          ];
        };
      };
    };
}
