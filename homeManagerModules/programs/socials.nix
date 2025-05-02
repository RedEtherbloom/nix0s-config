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
    nixpkgs.config.permittedInsecurePackages = [
      "olm-3.2.16"
    ];

    home.packages = with pkgs; [
      vesktop
      element-desktop
      telegram-desktop
      threema-desktop
      signal-desktop-bin

      mumble
    ];
  };
}
