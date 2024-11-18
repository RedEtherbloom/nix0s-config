{
  config,
  lib,
  inputs,
  osConfig,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    inputs.sops-nix.homeManagerModules.sops

    # I should redo this to import name.nix or name/default.nix. How though?
    (lib.filesystems.listFilesRecursive ./programs)
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  xdg.userDirs.createDirectories = true;
  programs.home-manager.enable = true;

  programs.nix-index-database.comma.enable = osConfig.programs.nix-index-database.comma.enable;

  home.packages = [
    (pkgs.writeShellApplication {
      name = "update-system";
      runtimeInputs = [ pkgs.git ];
      text = ''
        # TODO: The hard-coded path is eww
        cd ${config.home.homeDirectory}/Projects/nix0s-config
        git pull
        git add dotfiles/wallpaper/*
        nix flake update -v
        sudo nixos-rebuild --flake . switch -v -L --show-trace
        git restore --staged dotfiles/wallpaper/*
        git add flake.lock
      '';
    })
  ];
}
