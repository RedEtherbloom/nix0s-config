{
  flake.homeModules.art = {pkgs, ...}: {
    home.packages = [
      (pkgs.inkscape-with-extensions.override {inkscapeExtensions = [pkgs.inkscape-extensions.inkstitch];})
      pkgs.audacity
      pkgs.gimp
      pkgs.shotcut
    ];
  };
}
