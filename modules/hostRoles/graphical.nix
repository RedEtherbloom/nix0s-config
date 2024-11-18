{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix

    ./base.nix
  ];

  stylix = {
    enable = true;
    polarity = "dark";
  };
}
