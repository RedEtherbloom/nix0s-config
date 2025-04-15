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
      vesktop
      element-desktop
      telegram-desktop
      threema-desktop
      signal-desktop-bin

      mumble
    ];
  };
}
