{ inputs, pkgs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix

    ./base.nix
  ];

  stylix = {
    enable = true;
    polarity = "dark";
  };

  # For some reason this keeps getting pulled in since stlix and then recycled by ghc
  environment.systemPackages = with pkgs; [
    ghc
  ];
}
