{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in {
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  options.myOptions.hostRoles.neural-augmenter.enable = mkEnableOption "workstation options";

  config = mkIf cfg.enable {
    myOptions.hostRoles.graphical.enable = lib.mkDefault true;
    myOptions.office.enable = true;

    stylix = {
      enable = true;
      polarity = "dark";
      targets.grub.useImage = true;
      # Workaround for bug https://github.com/danth/stylix/issues/835
      targets.qt.platform = "kde";
    };

    # Open the ports for KDE-Connect and install it here as well.
    # HM can't open ports sadly.
    programs.kdeconnect = {
      enable = true;
      package = mkForce pkgs.kdePackages.kdeconnect-kde;
    };

    programs.adb.enable = true;

    # TODO: Maybe turn this into a home-manager option
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
    };

    environment.systemPackages = with pkgs; [
      # For some reason this keeps getting pulled in since stylix and then recycled by ghc
      ghc
      gnupg
      pinentry-qt

      lm_sensors
    ];

    myOptions.utilities = {
      rescueTools = true;
      binaryTools = true;
      pdfUtils = true;
      diskUtilities = true;
    };

    myOptions.roles.i2p.enable = true;

    services.tailscale.enable = true;
  };
}
