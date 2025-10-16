{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.myOptions.roles.hyprland;
in {
  options.myOptions.roles.hyprland = {
    enable = lib.mkOption {
      description = "Our custom hyprland config.";
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    # Inspired by:
    # - https://gitlab.com/Zaney/zaneyos/-/blob/main/modules/home/hyprland/default.nix
    wayland.windowManager.hyprland = {
      enable = true;
      # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
      package = null;
      portalPackage = null;
      # Properly setup systemd
      systemd = {
        enable = true;
        enableXdgAutostart = true;
        variables = ["--all"];
      };
      xwayland.enable = true;
      settings = {
        "$mod" = "SUPER";
        input = {
          kb_layout = "us,de";
          kb_variant = "colemak_dh_iso,nodeadkeys";
          # TODO: Add a compose key for e.g. chinese characters
          kb_options = "terminate:ctrl_alt_bksp,caps:escape,shift:both_capslock";
          kb_model = "pc104";
          numlock_by_default = true;
        };
        debug = {
          disable_logs = false;
          disable_time = false;
          overlay = true;
        };
        bind =
          [
            "SUPER, E, exec, firefox"
            "SUPER_SHIFT, E, exec, firefox -P work"
            # TODO: Work mode shortcut with: Work firefox, youtube music, obsidian
            "SUPER, Enter, exec, kitty"
            # TODO: Setup to autoswitch to it on the same keybinding
            "SUPER, N, exec, obsidian"
            "SUPER_SHIFT, N, exec, neovide"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
            builtins.concatLists (builtins.genList (
                i: let
                  ws = i + 1;
                in [
                  "$mod, code:1${toString i}, workspace, ${toString ws}"
                  "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
                ]
              )
              9)
          );
      };
    };

    # TODO: Look over
    home.packages = with pkgs; [
      swww
      grim
      slurp
      wl-clipboard
      swappy
      ydotool
      hyprpolkitagent
      hyprshot
      hyprland-qtutils # needed for banners and ANR messages
    ];
  };
}
