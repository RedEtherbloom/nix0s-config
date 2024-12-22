{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Supposedly required for e.g. systemd autocompletion
  environment.pathsToLink = [ "/share/zsh" ];
}
