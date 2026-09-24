{
  flake.homeModules.thunderbird = {pkgs, ...}: {
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird;
      profiles.personal = {
        isDefault = true;
        withExternalGnupg = true;
      };
    };
  };
}
