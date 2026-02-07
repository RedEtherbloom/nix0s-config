{lib, ...}: {
  imports =
    [
      ./roles/art.nix
      ./roles/development.nix
      ./roles/gamedev.nix
      ./roles/gaming.nix
      ./roles/nvim.nix
      ./roles/office.nix
      ./roles/vtubing.nix
    ]
    ++ (lib.flatten (lib.map (folder: lib.filesystem.listFilesRecursive folder) [./hostRoles ./programs ./services])); # TODO: Remove this for better readability
}
