{self, ...}: {
  flake = {
    nixosModules.gaming = {pkgs, ...}: {
      imports = [
        self.homeModules.gaming
      ];
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

            extraPkgs = pkgs: [
              pkgs.keyutils
              pkgs.libXScrnSaver
              pkgs.libXi
              pkgs.libXinerama
              pkgs.libXrandr
              pkgs.libXxf86vm
              pkgs.libgdiplus
              pkgs.libkrb5
              pkgs.libpng
              pkgs.libpulseaudio
              pkgs.libvorbis
              pkgs.libxkbfile
              pkgs.stdenv.cc.cc.lib
              #RimSort
              pkgs.nss
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
          capSysNice = false;
        };
        steam.gamescopeSession.enable = true;
      };
    };
    homeModules.gaming = {pkgs, ...}: {
      home.packages = with pkgs; [
        # _2ship2harkinian # Ocarina of Time
        # (olympus.override {celesteWrapper = pkgs.steam-run;})
        ut1999

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
  };
}
