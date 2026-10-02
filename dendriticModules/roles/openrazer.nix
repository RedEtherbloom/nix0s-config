{
  flake.nixosModules.openrazer = {pkgs, ...}: {
    hardware.openrazer.enable = true;
    environment.systemPackages = [
      pkgs.openrazer-daemon
      pkgs.polychromatic
    ];
    users.users.inf.extraGroups = ["openrazer"];
  };
}
