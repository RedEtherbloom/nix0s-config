{
  self,
  inputs,
  ...
}: {
  flake = {
    nixosModules.email = {
      imports = [
        self.nixosModules.gnome-dependencies
      ];
      home-manager.sharedModules = [
        self.homeModules.email
      ];

      programs.geary.enable = true;
    };
    homeModules.email = {pkgs, ...}: {
      imports = [
        inputs.secrets.homeModules.email
      ];
      programs.notmuch.enable = true;
      # IMPROVEMENT: Use the respective options
      home.packages = [
        pkgs.notmuch
        # And one of the following
        pkgs.lieer
        # pkgs.isync
        # pkgs.offlineimap
      ];
    };
  };
}
