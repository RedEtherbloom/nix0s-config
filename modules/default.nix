{
  imports = [
    ./common/localisation.nix
    ./common/security.nix
    ./common/shared_secrets.nix
    ./hostRoles/base.nix
    ./hostRoles/graphical.nix
    ./hostRoles/neural-augmenter.nix
    ./roles/gamedev.nix
    ./roles/gaming.nix
    ./roles/i2p.nix
    ./roles/office.nix
    ./roles/ssdp.nix
    ./roles/utilities.nix
    ./roles/vtubing.nix
    ./services/gitea.nix
  ];
}
