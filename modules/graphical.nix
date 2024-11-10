{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix

    ./base.nix
  ];

  stylix = {
    enable = true;
    image = ../dotfiles/wallpaper/test_image.jpg;
    polarity = "dark";
  };
}
