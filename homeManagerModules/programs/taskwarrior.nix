{
  osConfig,
  ...
}:
{
  services.taskwarrior-sync.enable = true;

  programs.taskwarrior = {
    enable = true;
    extraConfig = ''
      include ${osConfig.sops.templates."taskwarrior-sync.rc".path}
    '';
  };
}
