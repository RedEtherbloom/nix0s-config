{
  imports = [
    ../../homeManagerModules
  ];

  home.stateVersion = "25.05";
  # Let's try out McFly on our beefier machine
  programs.mcfly = {
    enable = false;
    fzf.enable = true;
    keyScheme = "vim";
  };
}
