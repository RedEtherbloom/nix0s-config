{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in {
  options.myOptions.hostRoles.neural-augmenter.enable = mkEnableOption "workstation options";

  config = mkIf cfg.enable {
    myOptions.hostRoles.graphical.enable = lib.mkDefault true;
    myOptions.office.enable = true;

    programs.adb.enable = true;

    # TODO: Maybe turn this into a home-manager option
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
    };

    environment.systemPackages = with pkgs; [
      gnupg
      pinentry-qt
    ];
  };
}
