{self, ...}: {
  flake = {
    nixosModules.office = {lib, ...}: {
      imports = [
        self.homeModules.office
      ];
      services.printing.enable = lib.mkDefault true;

      hardware.sane = {
        enable = true;
        drivers.scanSnap.enable = true;
      };
    };
    homeModules.office = {pkgs, ...}: {
      imports = [
        self.homeModules.thunderbird
      ];

      home.packages = [
        pkgs.libreoffice
        pkgs.hunspell
        pkgs.hunspellDicts.en_US
        pkgs.hunspellDicts.de_DE
        pkgs.pdfarranger
        pkgs.simple-scan
      ];
    };
  };
}
