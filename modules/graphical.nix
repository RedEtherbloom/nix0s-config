{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix

    ./base.nix
  ];

  stylix = {
    enable = true;
    image = ../dotfiles/wallpaper/manaria_cuddles.jpg;
    polarity = "dark";
  };
}
