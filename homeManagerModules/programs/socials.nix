{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.socials;
in {
  options.myOptions.socials = {
    enable = mkOption {
      description = "Enable socials";
      type = with types; bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (pkgs.discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
      element-desktop-wayland
      telegram-desktop
      threema-desktop
      signal-desktop

      mumble
    ];
  };
}
