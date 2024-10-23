{ pkgs, ... }:
{
  # ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    vteIntegration = true;
    autosuggestions = {
      enable = true;
      strategy = [
        "match_prev_cmd"
        "history"
        "completion"
      ];
    };
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      theme = "ys";
      plugins = [
        "git"
        "thefuck"
      ];
    };

    shellAliases = {
      ll = "ls -l";
      check-nix-config = "sudo nix-instantiate '<nixpkgs/nixos>' -A system";
      zix-shell = "nix-shell --command 'zsh'";
    };

    histSize = 10000;
  };
  users.defaultUserShell = pkgs.zsh;
}
