{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.plasma-manager;
in {
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  options.myOptions.plasma-manager = {
    enable = mkOption {
      description = "Enable plasma manager and applications";
      type = with types; bool;
      default = false;
    };
    krohnkite = mkOption {
      description = "Enable krohnkite tiling WM shortcuts";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # Plasma Manager
    programs.plasma = {
      enable = true;
    };

    services.kdeconnect = {
      enable = true;
      indicator = false;
      package = with pkgs; kdePackages.kdeconnect-kde;
    };

    home.packages = with pkgs.kdePackages;
      [
        kate
        kalk
      ]
      ++ lib.optionals cfg.krohnkite [krohnkite];
  };
}
