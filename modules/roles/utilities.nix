{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.utilities;
in {
  options.myOptions.utilities = {
    enable = mkOption {
      description = "Enable various utilities";
      type = with types; bool;
      default = false;
    };
    wormhole = mkOption {
      description = "Enable wormhole";
      type = types.bool;
      default = true;
    };
    tmux = mkOption {
      description = "Enable tmux";
      type = types.bool;
      default = true;
    };
    ssh_utils = mkOption {
      description = "Enable ssh_utils";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.wormhole {
      environment.systemPackages = with pkgs; [
        magic-wormhole
        magic-wormhole-rs
      ];
    })
    (mkIf cfg.tmux {environment.systemPackages = [pkgs.tmux];})
    (mkIf cfg.ssh_utils {
      environment.systemPackages = with pkgs; [
        sshfs
        mosh
      ];
    })
  ]);
}
