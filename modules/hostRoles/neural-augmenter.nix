{ config, lib, ... }:
with lib;
let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in
{
  options.myOptions.hostRoles.neural-augmenter.enable = mkEnableOption "workstation options";

  config = mkIf cfg.enable {
    myOptions.hostRoles.graphical.enable = lib.mkDefault true;
  };
}