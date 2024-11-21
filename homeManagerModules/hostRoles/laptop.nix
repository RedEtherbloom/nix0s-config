{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.laptop;
in {
  options.myOptions.hostRoles.laptop = {
    enable = mkOption {
      description = "Enable laptop";
      type = with types; bool;
      default = osConfig.myOptions.hostRoles.laptop.enable;
    };
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = mkDefault true;
  };
}
