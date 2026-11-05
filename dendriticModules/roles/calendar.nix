{self, ...}: {
  flake = {
    nixosModules.calendar = {
      imports = [
        self.nixosModules.gnome-dependencies
      ];

      home-manager.sharedModules = [
        self.homeModules.calendar
      ];

      services.gnome.evolution-data-server.enable = true;
    };
    homeModules.calendar = {pkgs, ...}: {
      home.packages = [
        pkgs.gnome-calendar
      ];
    };
  };
}
