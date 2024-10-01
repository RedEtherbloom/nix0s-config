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

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs: {
    nixosConfigurations = {
      neurodrive = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/neurodrive/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.default
        ] ++ (with inputs.nixos-hardware.nixosModules; [
          common-gpu-nvidia-nonprime
          common-hidpi
          # Xeon CPU
          common-cpu-intel-cpu-only
          common-pc
          common-pc-ssd
        ]);	
      };
      fractor = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/fractor/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.default
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x230
        ];
      };
    };
  };
}
