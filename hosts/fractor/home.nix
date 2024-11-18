{
  imports = [
    ../../homeManagerModules/hostRoles/laptop.nix
  ];

  home.stateVersion = "24.05";
  # Main taskwarrior client
  programs.taskwarrior.config."recurrence" = "on";
}