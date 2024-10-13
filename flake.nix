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
              ./modules/desktop.nix
              {
                home-manager.users.inf.imports = [
                  { home.stateVersion = "24.05"; }
                  ./homeManagerModules/desktop.nix
                ];
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
            {
              home-manager.users.inf.imports = [
                { home.stateVersion = "24.05"; }
                ./homeManagerModules/laptop.nix
              ];
            }
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nixos-hardware.nixosModules.lenovo-thinkpad-x230
          ];
        };
      };
    };
}
