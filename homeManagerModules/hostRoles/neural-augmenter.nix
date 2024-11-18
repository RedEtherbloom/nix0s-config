{
  imports = [
    ./graphical.nix
  ];

  myOptions.obsidian.enable = true;
  myOptions.taskwarrior = {
    enable = true;
    enableSync = true;
    taskopen = true;
  };
}
