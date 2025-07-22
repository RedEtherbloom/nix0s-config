{pkgs, ...}: {
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # TODO: Why do systemd completions lag so much?
  # See: https://home-manager-options.extranix.com/?query=programs.zsh.enableCompletion&release=master
  environment.pathsToLink = ["/share/zsh"];
}
