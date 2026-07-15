{ pkgs, ... }: {
  imports = [
    ../../homeManagerModules
  ];

  home = {
    stateVersion = "24.05";
    packages = with pkgs; [
      aircrack-ng
    ];
  };

  programs.niri.settings.outputs."eDP-1".scale = 1.0;
}
