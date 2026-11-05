{self, ...}: {
  flake = {
    nixosModules.gnome-dependencies = {
      home-manager.sharedModules = [
        self.homeModules.gnome-dependencies
      ];

      services.accounts-daemon.enable = true;
      services.gnome = {
        gnome-online-accounts.enable = true;
        gnome-settings-daemon.enable = true;
        glib-networking.enable = true;
      };
    };
    homeModules.gnome-dependencies = {pkgs, ...}: {
      home.packages = [
        pkgs.gnome-control-center
        pkgs.gnome-weather
        pkgs.gnome-calculator
        pkgs.gnome-clocks
      ];
    };
  };
}
