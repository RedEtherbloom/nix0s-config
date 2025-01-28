{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.zsh;
in {
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
      autosuggestion = {
        enable = true;
      };
      syntaxHighlighting = {
        enable = true;
      };
      oh-my-zsh = {
        enable = true;
        theme = "random";
        plugins = [
          "git"
        ];
      };
      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];

      shellAliases = {
        ll = "ls -l";
        tt = "taskwarrior-tui";
        # TODO: This probably needs a flake rewrite
        check-nix-config = "sudo nix-instantiate '<nixpkgs/nixos>' -A system";
        zix-shell = "nix-shell --command 'zsh'";
        ztheme = "(){ export ZSH_THEME=\"$@\" && source $ZSH/oh-my-zsh.sh }";
        captive_portal_ip = "ip route get 1.1.1.1 | rg 'via ([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+) dev' -or '$1'";
        copy_captive_portal_ip = "captive_portal_ip | wl-copy";

        lz = "lazygit";
      };

      initExtra = ''
        # FVim ignores Nix result/ symlink
        function fvim() {
          fd --type f --strip-cwd-prefix --exclude="result"/ | fzf --query "$*" --multi --bind "enter:become(nvim {+})";
        }
      '';
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.zoxide.enable = true;
  };
}
