{inputs, ...}: {
  flake.homeModules.flatpak = {pkgs, ...}: {
    imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;
      remotes = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "flathub-beta";
          location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
        }
      ];
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
