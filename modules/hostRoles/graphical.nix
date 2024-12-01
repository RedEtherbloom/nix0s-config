{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.graphical;
in {
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  options.myOptions.hostRoles.graphical.enable = mkEnableOption "graphical session settings";

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;

    stylix = {
      enable = true;
      polarity = "light";
    };

    # Open the ports for KDE-Connect and install it here as well.
    # HM can't open ports sadly.
    programs.kdeconnect = {
      enable = true;
      package = mkForce pkgs.kdePackages.kdeconnect-kde;
    };

    # For some reason this keeps getting pulled in since stlix and then recycled by ghc
    environment.systemPackages = with pkgs; [
      ghc
    ];
  };
}
