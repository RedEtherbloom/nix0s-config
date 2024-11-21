{ lib, ... }:
{
  imports = [
    ./common
    ./event-setup.nix
    ./hostRoles
    ./services
    ./wireguard
  ] ++ (lib.flatten (lib.map (folder: lib.filesystem.listFilesRecursive folder) [./roles]));
}
