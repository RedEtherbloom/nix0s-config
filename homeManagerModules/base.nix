{
  config,
  inputs,
  osConfig,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    inputs.sops-nix.homeManagerModules.sops

    ./programs/zsh.nix
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
        nix flake update -v
        sudo nixos-rebuild --flake . switch -v -L --show-trace
        git add .
      '';
    })
  ];
}
