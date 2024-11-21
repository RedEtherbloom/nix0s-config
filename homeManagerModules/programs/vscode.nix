{
  config,
  lib,
  pkgs,
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
      );
      userSettings = {
        nix = {
          enableLanguageServer = true;
          serverPath = "nixd";
          serverSettings = {
            nixd = {
              formatting.command = ["alejandra"];
              /*
                options = {
                  home-manager = {
                      expr = "(builtins.getFlake \"/absolute/path/to/flake\").homeConfigurations.<name>.options";
                  };
              };
              */
            };
          };
        };
        git = {
          autofetch = true;
          confirmSync = false;
        };
        gitlens.views.branches.branches.layout = "list";
        redhat.telemetry.enabled = false;
      };
    };

    stylix.targets.vscode.enable = false;
  };
}
