{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.gaming;
in {
  options.myOptions.roles.gaming.enable = lib.mkEnableOption "steam and gaming";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = true;
      package = pkgs.steam.override {
        # Disable the GUI popping up on startup
        extraArgs = "-silent";

        extraPkgs = pkgs:
          with pkgs; [
            libgdiplus
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            xorg.libXcursor
            xorg.libxkbfile
            xorg.libXi
            xorg.libXinerama
            xorg.libXrandr
            xorg.libXxf86vm

            #RimSort
            nss
          ];
      };
    };
  };
}
