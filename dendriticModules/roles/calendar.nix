{
  self,
  # inputs,
  ...
}: {
  flake = {
    nixosModules.calendar = {
      home-manager.sharedModules = [
        self.homeModules.calendar
      ];
    };
    homeModules.calendar = {pkgs, ...}: {
      imports = [
        # inputs.secrets.homeModules.calendar # TODO: Setup
      ];
      home.packages = [
        pkgs.gnome-calendar
      ];
    };
  };
}
