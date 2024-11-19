{ config, inputs, lib, pkgs, ... }:
with lib;
let
  cfg = config.myOptions.plasma-manager;
in
{
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  options.myOptions.plasma-manager = {
    enable = mkOption {
      description = "Enable plasma manager and applications";
      type = with types; bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    # Plasma Manager
    programs.plasma = {
      enable = true;
    };

    home.packages = with pkgs; [
      kate
      kdePackages.kalk
    ];
  };
}
