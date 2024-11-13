{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix

    ./base.nix
  ];

  stylix = {
    enable = true;
    image = ../dotfiles/wallpaper/catgirl.jpg;
    polarity = "dark";
  };
}
