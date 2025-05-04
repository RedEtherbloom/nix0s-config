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
    myOptions = {
      hostRoles.graphical.enable = lib.mkDefault true;
      office.enable = true;
      utilities = {
        rescueTools = true;
        binaryTools = true;
        pdfUtils = true;
        diskUtilities = true;
      };
      roles.i2p.enable = true;
    };

    stylix = {
      enable = true;
      polarity = "dark";
      targets.grub.useImage = true;
    };

    programs = {
      # Open the ports for KDE-Connect and install it here as well.
      # HM can't open ports sadly.
      kdeconnect = {
        enable = true;
        package = mkForce pkgs.kdePackages.kdeconnect-kde;
      };

      adb.enable = true;

      # TODO: Maybe turn this into a home-manager option
      gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-qt;
      };
    };

    services = {
      tailscale.enable = true;

      udev.packages = with pkgs; [
        platformio-core
      ];
    };

    environment.systemPackages = with pkgs; [
      # For some reason this keeps getting pulled in since stylix and then recycled by ghc
      ghc
      gnupg
      pinentry-qt

      lm_sensors
    ];

    # Required for Nheko to work
    nixpkgs.config.permittedInsecurePackages = [
      "olm-3.2.16"
    ];
  };
}
