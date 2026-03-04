{
  config,
  lib,
  ...
}: let
  cfg = config.myOptions.hostRoles.laptop;
in {
  options.myOptions.hostRoles.laptop.enable = lib.mkEnableOption "laptop options";

  config = lib.mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = lib.mkDefault true;
  };
}
