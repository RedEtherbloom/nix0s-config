{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  inherit (import ../../homeManagerModules/lib/plasma_lib.nix {inherit pkgs;}) define-kscreen-layout;
  inherit (import ../../homeManagerModules/lib/torrent_lib.nix {inherit osConfig pkgs;}) vopono-torrent;
in {
  imports = [
    ../../homeManagerModules
  ];

  config = lib.mkMerge [
    (let
      vopono-torrent-desktop =
        pkgs.makeDesktopItem
        {
          name = "Vopono_Torrent";
          desktopName = "Vopono Torrent";
          exec = "${lib.getExe vopono-torrent}";
          icon = "qbittorrent";
          comment = "Start qbittorrent and associated plugins and applications in a vopono workspace.";
          categories = [
            "X-Multimedia"
            "X-Internet"
            "X-Utilities"
          ];
        };
    in {
      home = {
        stateVersion = "24.05";
        packages = with pkgs; [
          # FNV Mod launcher
          zenity
          yad
          # Does my bar approach need this?
          openal

          # TODO: Maybe this will make KRunner less laggy
          egl-wayland

          koboldcpp
          # comfyuiPackages.comfyui-with-extensions

          coolercontrol.coolercontrol-gui

          gsmartcontrol
          kdePackages.plasma-disks
          lmstudio
          sillytavern

          sidequest
          immersed

          # VRChat tools
          oscavmgr
          vrcadvert
          vrcx
          vrc-get
          alcom

          # Trying to avoid a stylix issue preventing startup
          kdePackages.qtstyleplugin-kvantum

          vopono-torrent-desktop
        ];
      };

      myOptions.solaar = {
        enable = true;
        autostart.enable = true;
      };

      # Let's try out McFly on our beefier machine
      programs = {
        mcfly = {
          enable = false;
          fzf.enable = true;
          keyScheme = "vim";
        };
        btop.package = pkgs.btop-cuda;
      };

      xdg = {
        autostart = {
          enable = true;
          entries = lib.lists.map (desktop: "${desktop}/share/applications/${desktop.name}.desktop") [
            vopono-torrent-desktop
          ];
        };
      };
    })
    (define-kscreen-layout "benq" "output.DP-3.disable output.HDMI-A-1.disable output.DP-2.enable output.DP-2.rotation.normal output.DP-2.position.0,0" "ctrl+shift+f1")
    (define-kscreen-layout "dual" "output.HDMI-A-1.disable output.DP-2.enable output.DP-2.position.1080,420 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.right output.DP-3.position.0,0" "ctrl+shift+f2")
    (define-kscreen-layout "aoc" "output.HDMI-A-1.disable output.DP-3.enable output.DP-3.position.0,0 output.DP-3.rotation.right output.DP-2.disable" "ctrl+shift+f3")
    (define-kscreen-layout "lg" "output.DP-2.disable output.DP-3.disable output.HDMI-A-1.enable output.HDMI-A-1.position.0,0" "ctrl+shift+f4")
    (define-kscreen-layout "lg-aoc" "output.DP-2.disable output.HDMI-A-1.enable output.HDMI-A-1.position.1080,420 output.HDMI-A-1.priority.1 output.DP-3.enable output.DP-3.position.0,0 output.DP-3.rotation.right" "ctrl+shift+f5")
    (define-kscreen-layout "lg-benq" "output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.disable output.HDMI-A-1.enable output.HDMI-A-1.position.1920,0 output.HDMI-A-1.rotation.normal output.HDMI-A-1.priority.2" "ctrl+shift+f6")
    (define-kscreen-layout "trial" "output.DP-2.enable output.DP-2.position.1080,420 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.right output.DP-3.position.0,0 output.DP-3.priority.2 output.HDMI-A-1.enable output.HDMI-A-1.position.3000,420 output.HDMI-A-1.rotation.normal output.HDMI-A-1.priority.3" "ctrl+shift+f7")
  ];
}
