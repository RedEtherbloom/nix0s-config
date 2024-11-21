{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.graphical;
in {
  options.myOptions.hostRoles.graphical.enable = mkOption {
    description = "graphical hostRole hm settings";
    type = with types; bool;
    default = osConfig.myOptions.hostRoles.graphical.enable;
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;

    # Remove files for stylix
    # TODO: Try to disable this in KDE
    home.activation = {
      removeStylixBlockersAction = lib.hm.dag.entryBefore ["checkFilesChanged"] ''
        run rm -rf ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.gtkrc-2.0
      '';
    };

    myOptions.plasma-manager.enable = true;
  };
}
