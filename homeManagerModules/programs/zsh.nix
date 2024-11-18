{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.myOptions.zsh;
in
{
  options.myOptions.zsh = {
    enable = mkOption {
      description = "Enable ZSH and Oh-My-Zsh";
      type = with types; bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      autosuggestion = {
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
        # TODO: This probably needs a flake rewrite
        check-nix-config = "sudo nix-instantiate '<nixpkgs/nixos>' -A system";
        zix-shell = "nix-shell --command 'zsh'";
        ztheme = "(){ export ZSH_THEME=\"$@\" && source $ZSH/oh-my-zsh.sh }";
      };
    };

    programs.zoxide.enable = true;
    programs.thefuck.enable = true;
  };
}
