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
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        protontricks.enable = true;
        extest.enable = true;
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
              libXcursor
              libxkbfile
              libXi
              libXinerama
              libXrandr
              libXxf86vm
              #RimSort
              nss

              # Gamescope
              libXcursor
              libXi
              libXinerama
              libXScrnSaver
              libpng
              libpulseaudio
              libvorbis
              stdenv.cc.cc.lib # Provides libstdc++.so.6
              libkrb5
              keyutils
              # Add other libraries as needed
            ];
        };
      };
      gamemode = {
        enable = true;
        settings.custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
      gamescope = {
        enable = true;
        enableWsi = true;
        capSysNice = true;
      };
    };
  };
}
