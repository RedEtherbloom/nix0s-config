{ lib, inputs, ... }:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    inputs.sops-nix.nixosModules.sops

    ./default.nix
  ];

  programs.nix-index-database.comma.enable = lib.mkDefault true;
}
