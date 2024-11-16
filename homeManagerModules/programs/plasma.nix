{ inputs, ... }: {
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  # Plasma Manager
  programs.plasma = {
    enable = true;
  };
}