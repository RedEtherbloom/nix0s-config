{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix

    ./base.nix
  ];

  # TODO: This should really be per device and potentially stored out-of-this-repo
  stylix = {
    enable = true;
    image = ../dotfiles/wallpaper/catgirl_waifu2x_noise2_scale4x.png;
    polarity = "dark";
  };
}
