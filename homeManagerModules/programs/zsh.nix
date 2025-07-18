{
  config,
  lib,
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
        enableVteIntegration = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "flazz";
          plugins = [
            "git"
            # TODO: Replace with zsh-vi-mode
            "vi-mode"
          ];
        };
        history = {
          append = true;
          expireDuplicatesFirst = true;
          # Timestamps
          extended = true;
          # TODO: Do we still get the latest printed, or does it ignore e.g. both?
          findNoDups = true;
          # Discard the older dup
          ignoreAllDups = true;
          ignoreSpace = true;
        };
        sessionVariables = {
          # Hoping to make vi mode and nvim more responsive
          KEYTIMEOUT = 1;
          ZVM_LINE_INIT_MODE = "ZVM_MODE_INSERT";
          ZVM_VI_INSERT_ESCAPE_BINDKEY = "jj";
          VI_MODE_RESET_PROMPT_ON_MODE_CHANGE = true;
          # Normal mode Vi-Mode
          MODE_INDICATOR = "%F{white}+NORMAL%f";
          # Insert mode Vi-Mode
          INSERT_MODE_INDICATOR = "%F{yellow}+INSERT%f";
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
      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
      # TODO: Read into and learn
      zellij = {
        enable = false;
        enableZshIntegration = true;
      };
    };
  };
}
