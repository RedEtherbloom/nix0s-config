{ inputs, lib, ... }:
{
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
    ./base.nix
  ];

  # Remove files for stylix
  home.activation = {
    removeStylixBlockersAction = lib.hm.dag.entryBefore [ "stylixLookAndFeel" ] ''
      run rm -rf ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.gtkrc-2.0
    '';
  };
}
