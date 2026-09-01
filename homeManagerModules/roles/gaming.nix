{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.gaming;
in {
  options.myOptions.roles.gaming.enable = lib.mkOption {
    description = "Install games";
    type = lib.types.bool;
    default = osConfig.myOptions.roles.gaming.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      steam
      # _2ship2harkinian
      # ut1999
      # (olympus.override {celesteWrapper = pkgs.steam-run;})

      (lutris.override {
        extraLibraries = pkgs: [
          pkgs.glib-networking
          pkgs.dconf
          pkgs.gamemode.lib
        ];
        extraPkgs = pkgs: [
          pkgs.vulkan-tools
        ];
      })
    ];
  };
}
