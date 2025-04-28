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
    programs = {
      zsh = {
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
          theme = "flazz";
          plugins = [
            "git"
            "vi-mode"
          ];
        };

        sessionVariables = {
          ZVM_LINE_INIT_MODE = "ZVM_MODE_INSERT";
        };

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

          # Giant shitpost
          awaken = "";
          my = "";
          masters = "xdg-open 'https://www.youtube.com/watch?v=ZDEbsZpweDo&pp=ygUSYXdha2VuIG15IG1hc3RlcnMg' && sleep 7 && git submodule update --init --recursive --verbose && git submodule status";
        };

        initContent = ''
          # FVim ignores Nix result/ symlink
          function fvim() {
            fd --type f --strip-cwd-prefix --exclude="result"/ | fzf --query "$*" --multi --bind "enter:become(nvim {+})";
          }
        '';
      };

      fzf = {
        enable = true;
        enableZshIntegration = true;
      };

      zoxide.enable = true;
    };
  };
}
