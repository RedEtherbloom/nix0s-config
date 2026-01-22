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
      steam
      steam-tui
      gcs
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
      wineWowPackages.stable
      (prismlauncher.override {
        additionalLibs = with pkgs; [
          nss
          nspr
          libgbm
          glib
          at-spi2-atk
          cups
          libdrm
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXfixes
          xorg.libX11
          xorg.libXext
          xorg.libXrandr
          xorg.libxcb
          expat
          libxkbcommon
          dbus
          pango
          cairo
          stdenv.cc.cc.lib
        ];
        # Optional
        additionalPrograms = [pkgs.ffmpeg];
      })
      ut1999
    ];
    programs.mangohud.enable = true;
  };
}
