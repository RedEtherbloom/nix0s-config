{
  config,
  lib,
  osConfig,
  pkgs,
  self,
  ...
}:
with lib; let
  cfg = config.myOptions.vscode;
  cfg_development = config.myOptions.roles.development;
in {
  options.myOptions.vscode = {
    enable = mkOption {
      description = "Enable vscode";
      type = with types; bool;
      default = false;
    };
    vimMode = mkOption {
      description = "Enable Vim mode plugin";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      mutableExtensionsDir = false;
      enableExtensionUpdateCheck = false;
      extensions = (
        with pkgs.vscode-extensions;
          [
            mhutchie.git-graph
            donjayamanne.githistory
            eamodio.gitlens
            ms-vscode-remote.remote-ssh
            mkhl.direnv
            streetsidesoftware.code-spell-checker
            redhat.vscode-yaml
            bierner.markdown-mermaid
            jebbs.plantuml
            hediet.vscode-drawio
            pkgs.vscode-marketplace.wenfangdu.snippet-generator
            christian-kohler.path-intellisense
          ]
          ++ lib.optionals cfg.vimMode [
            vscodevim.vim
          ]
          ++ lib.optionals cfg_development.vscode-accessibility [
            oderwat.indent-rainbow
          ]
          ++ lib.optionals cfg_development.nix [
            jnoortheen.nix-ide
            arrterian.nix-env-selector
          ]
          ++ lib.optionals cfg_development.python [
            ms-python.python
            ms-python.flake8
          ]
          ++ lib.optionals cfg_development.docker [
            ms-azuretools.vscode-docker
          ]
          ++ lib.optionals cfg_development.rust [
            vadimcn.vscode-lldb
            rust-lang.rust-analyzer
            tamasfe.even-better-toml
          ]
          ++ lib.optionals cfg_development.java [
            vscjava.vscode-java-pack
          ]
          ++ lib.optionals cfg_development.openscad [
            antyos.openscad
          ]
          ++ lib.optionals cfg_development.github [
            github.vscode-github-actions
          ]
          ++ lib.optionals cfg_development.copilot [
            github.copilot
            github.copilot-chat
          ]
          ++ lib.optionals cfg_development.go [
            golang.go
          ]
      );
      userSettings = lib.mkMerge [
        {
          nix = {
            enableLanguageServer = true;
            serverPath = "nixd";
            serverSettings = {
              nixd = {
                formatting.command = [self.formatter];

                options = let
                  nixos = "(builtins.getFlake \"${self}\").nixosConfigurations.${osConfig.networking.hostName}.options";
                in {
                  nixos.expr = nixos;
                  # TODO: Rewrite flake.nix with homeManagerConfigurations in mind(read docs for that) as our own options are missing
                  home-manager.expr = nixos + ".home-manager.users.type.getSubOptions []";
                };
              };
            };
          };
          git = {
            autofetch = true;
            confirmSync = false;
          };
          gitlens.views.branches.branches.layout = "list";
          redhat.telemetry.enabled = false;
          # Fix swapcapsesc not being recognized in vscode
          keyboard.dispatch = "keyCode";
          # Spellchecker is way to verbose. Unknown words will not get flagged this way
          cSpell.reportUnknownWords = true;
        }
        (lib.optionalAttrs cfg_development.go {
          # Quarry: Supposedly better, according to vs-code docs
          gopls.ui.semanticTokens = cfg_development.go;
        })
        (lib.optionalAttrs cfg.vimMode {
          # Performance reasons
          extensions.experimental.affinity.vscodevim.vim = 1;
          vim.leader = "<space>";
          vim.handleKeys = {
            # Clara: Reenable filepicker(although we really need a good one for Vim in general)
            "<C-p>" = false;
            # Valerie: Reenable new file
            "<C-n>" = false;

            "<C-a>" = false;
            "<C-f>" = false;
          };
          vim.useSystemClipboard = true;
          vim.useCtrlKeys = true;
          # TODO: What does this mean?
          vim.insertModeKeyBindings = [
            {
              before = ["j" "j"];
              after = ["<Esc>"];
            }
          ];
          vim.normalModeKeyBindingsNonRecursive = [
            {
              before = ["<leader>" "d"];
              after = ["d" "d"];
            }
            # TODO: What does this mean?
            {
              before = ["<C-n>"];
              commands = ["=nohl"];
            }
            {
              before = ["K"];
              commands = ["lineBreakInsert"];
              silent = true;
            }
          ];
          # TODO: What does this mean?
          vim.easymotion = true;
          vim.incsearch = true;
          vim.hlsearch = true;
        })
      ];
    };

    stylix.targets.vscode.enable = true;
  };
}
