{lib, ...}: {
  imports =
    []
    # I should redo this to import name.nix or name/default.nix. How though?
    ++ (lib.flatten (lib.map (folder: lib.filesystem.listFilesRecursive folder) [./hostRoles ./programs ./roles ./services]));
}
