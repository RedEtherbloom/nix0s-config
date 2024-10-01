{ ... }:
{
  imports = [
    ./base_pkgs.nix
    ./security.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2w";
    };
    optimise = {
      automatic = true;
      dates = [
        "15:00"
      ];
    };
  };
  programs.nix-ld.enable = true;
  programs.appimage.binfmt = true;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
