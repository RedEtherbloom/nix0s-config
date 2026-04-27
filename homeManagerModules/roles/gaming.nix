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
      # gcs
      (olympus.override {celesteWrapper = pkgs.steam-run;})

      dxvk_2
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
      winetricks
      wineWow64Packages.waylandFull
      # (prismlauncher.override {
      #   additionalLibs = with pkgs; [
      #     nss
      #     nspr
      #     libgbm
      #     glib
      #     at-spi2-atk
      #     cups
      #     libdrm
      #     libXcomposite
      #     libXdamage
      #     libXfixes
      #     libX11
      #     libXext
      #     libXrandr
      #     libxcb
      #     expat
      #     libxkbcommon
      #     dbus
      #     pango
      #     cairo
      #     stdenv.cc.cc.lib
      #   ];
      #   # Optional
      #   additionalPrograms = [pkgs.ffmpeg];
      # })
      ut1999
      hyperspeedcube
      _2ship2harkinian
    ];
    programs.mangohud.enable = true;
  };
}
