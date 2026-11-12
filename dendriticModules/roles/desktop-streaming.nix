{self, ...}: {
  flake = {
    nixosModules.desktop-streaming = {
      home-manager.sharedModules = [
        self.homeModules.desktop-streaming
      ];

      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
      };

      users.users.inf.extraGroups = [
        "uinput"
      ];
    };
    homeModules.desktop-streaming = {pkgs, ...}: {
      home.packages = [
        pkgs.moonlight-qt
      ];
    };
  };
}
