{ config, ... }:
{
  # ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    autosuggestion = {
      # color = "fg=blue";
      highlight = "fg=#blue,bg=green,bold,underline";
      enable = true;
      strategy = [
        "completion"
        "match_prev_cmd"
        "history"
      ];
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "cursor"
      ];
      styles = {
        # My pancakes :3c
        cursor = "fg=purple,bg=green,bold,underline";
      };
    };

    oh-my-zsh = {
      enable = true;
      theme = "random";
      plugins = [
        "git"
        "thefuck"
      ];
    };

    shellAliases = {
      ll = "ls -l";
      tt = "taskwarrior-tui";
      check-nix-config = "sudo nix-instantiate '<nixpkgs/nixos>' -A system";
      zix-shell = "nix-shell --command 'zsh'";
      ztheme= "(){ export ZSH_THEME=\"$@\" && source $ZSH/oh-my-zsh.sh }";

      screen_aoc = "kscreen-doctor output.DP-3.enable output.DP-3.position.0,0 output.DP-2.disable output.DP-2.rotation.inverted";
      screen_benq = "kscreen-doctor output.DP-3.disable output.DP-2.enable output.DP-2.rotation.normal output.DP-2.position.0,0";
      screen_dual = "kscreen-doctor output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.inverted output.DP-3.position.1920,0";
    };
  };
}
