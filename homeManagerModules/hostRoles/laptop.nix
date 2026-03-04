{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.hostRoles.laptop;
in {
  options.myOptions.hostRoles.laptop = {
    enable = lib.mkOption {
      description = "Enable laptop";
      type = lib.types.bool;
      default = osConfig.myOptions.hostRoles.laptop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = lib.mkDefault true;

    home.packages = with pkgs; [
      intel-gpu-tools
    ];
    services.hypridle.settings.listener = [
      {
        timeout = 1800;
        on-timeout = "systemctl suspend-then-hibernate";
      }
    ];
  };
}
