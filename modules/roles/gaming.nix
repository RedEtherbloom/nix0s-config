{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.gaming;
in {
  options.myOptions.roles.gaming.enable = mkEnableOption "steam and gaming";

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = true;
      # X11 -> Wayland Input translation
      extest.enable = true;

      package = pkgs.steam.override {
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

    # SteamVR
    networking.firewall.allowedUDPPorts = [
      9944
      27062
    ];
    networking.firewall.allowedTCPPorts = [
      27062
    ];
  };
}
