{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.gaming;
in {
  options.myOptions.roles.gaming.enable = mkOption {
    description = "Install games";
    type = with types; bool;
    default = osConfig.myOptions.roles.gaming.enable;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gcs
      byar-launcher
      rimsort
      starsector
      (olympus.override {celesteWrapper = pkgs.steam-run;})

      dxvk_2
      lutris
      wineWowPackages.stable
    ];
  };
}
