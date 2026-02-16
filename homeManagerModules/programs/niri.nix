# TODO: Gate behind option declaration
{inputs, pkgs, osConfig, ...}: {
  imports = [
    inputs.niri-flake.homeModules.niri
    inputs.noctalia-shell.homeModules.default
  ];

  # TODO: Read through niri-flake stylix module
  programs.niri = {
    enable = true;
    inherit (osConfig.programs.niri) package;
  };

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default.override { calendarSupport = true;};
    systemd.enable = true; # See doc warnings about experimental status
    # TODO: Set niri target
  };
}
