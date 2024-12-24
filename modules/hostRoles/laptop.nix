{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.laptop;
in {
  options.myOptions.hostRoles.laptop.enable = mkEnableOption "laptop options";

  config = mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = lib.mkDefault true;
  };
}
