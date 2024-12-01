{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.socials;
  vars = import ../variables.nix {inherit lib config osConfig pkgs;};
in {
  options.myOptions.socials = {
    enable = mkOption {
      description = "Enable socials";
      type = with types; bool;
      default = false;
    };
    discord = {
      enable = mkOption {
        description = "Enable discord";
        type = types.bool;
        default = true;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.discord.override {
          withOpenASAR = true;
          withVencord = true;
        };
      };
      autostart.enable = mkOption {
        description = "Autostart discord";
        type = types.bool;
        default = true;
      };
    };
    telegram = {
      enable = mkOption {
        description = "Enable telegram";
        type = types.bool;
        default = true;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.telegram-desktop;
      };
      autostart.enable = mkOption {
        description = "Enable autostart";
        type = types.bool;
        default = true;
      };
    };
    matrix = {
      enable = mkOption {
        description = "Enable matrix client";
        type = types.bool;
        default = true;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.element-desktop-wayland;
      };
      autostart.enable = mkOption {
        description = "Autostart matrix client";
        type = types.bool;
        default = true;
      };
    };
    signal = {
      enable = mkOption {
        description = "Enable signal client";
        type = types.bool;
        default = true;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.signal-desktop;
      };
      autostart.enable = mkOption {
        description = "Autostart signal client";
        type = types.bool;
        default = true;
      };
    };
    threema = {
      enable = mkOption {
        description = "Enable threema client";
        type = types.bool;
        default = true;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.threema-desktop;
      };
      autostart.enable = mkOption {
        description = "Autostart threema client";
        type = types.bool;
        default = true;
      };
    };
    mumble = {
      enable = mkOption {
        description = "Enable mumble client";
        type = types.bool;
        default = true;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.mumble;
      };
      autostart.enable = mkOption {
        description = "Autostart mumble client";
        type = types.bool;
        default = false;
      };
    };
  };

  # TODO: This can be done prettier with some lambdas
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.discord.enable (
      mkMerge [
        {home.packages = [cfg.discord.package];}
        (mkIf cfg.discord.autostart.enable (vars.autostartApplicationFromPackage {package = cfg.discord.package;}))
      ]
    ))
    (mkIf cfg.telegram.enable (
      mkMerge [
        {home.packages = [cfg.telegram.package];}
        (mkIf cfg.telegram.autostart.enable (vars.autostartApplicationFromPackage {package = cfg.telegram.package;}))
      ]
    ))
    /*
    (cfg.matrix.enable (
      mkMerge [
        {home.packages = [cfg.matrix.package];}
        (mkIf cfg.matrix.autostart.enable vars.autostartApplicationFromPackage {package = cfg.matrix.package;})
      ]
    ))
    (cfg.signal.enable (
      mkMerge [
        {home.packages = [cfg.signal.package];}
        (mkIf cfg.signal.autostart.enable vars.autostartApplicationFromPackage {package = cfg.signal.package;})
      ]
    ))
    (cfg.threema.enable (
      mkMerge [
        {home.packages = [cfg.threema.package];}
        (mkIf cfg.threema.autostart.enable vars.autostartApplicationFromPackage {package = cfg.threema.package;})
      ]
    ))
    (cfg.mumble.enable (
      mkMerge [
        {home.packages = [cfg.mumble.package];}
        (mkIf cfg.mumble.autostart.enable vars.autostartApplicationFromPackage {package = cfg.mumble.package;})
      ]
    ))
    */
  ]);
}
