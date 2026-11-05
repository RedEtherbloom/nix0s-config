{self, ...}: {
  flake = {
    nixosModules.accessibility = {
      home-manager.sharedModules = [
        self.homeModules.accessibility
      ];

      services.gnome.at-spi2-core.enable = true;
    };
    homeModules.accessibility = {};
  };
}
