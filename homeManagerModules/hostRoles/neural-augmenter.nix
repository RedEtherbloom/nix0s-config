{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in {
  options.myOptions.hostRoles.neural-augmenter = {
    enable = mkOption {
      description = "workstation hm settings";
      type = with types; bool;
      default = osConfig.myOptions.hostRoles.neural-augmenter.enable;
    };
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.graphical.enable = mkDefault true;

    myOptions.roles.development.enable = true;
    myOptions.vscode.enable = true;
    myOptions.obsidian.enable = true;
    myOptions.taskwarrior = {
      enable = true;
      enableSync = true;
      taskopen = true;
    };
    myOptions.taskwarrior-tui = {
      enable = true;
      package = with pkgs; (taskwarrior-tui.overrideAttrs (oldAttrs: rec {
        version = oldAttrs.version + "-fix";

        src = (
          pkgs.fetchFromGitHub {
            owner = "RedEtherbloom";
            repo = "taskwarrior-tui";
            hash = "sha256-YNd4vtaWm+1fsB8ly3toq2u74Nicmhx2ey1m557q4K8=";
            rev = "ee24bfb4a36f246933e6d2502ab85d3fc6abb85b";
          }
        );

        cargoDeps = oldAttrs.cargoDeps.overrideAttrs (
          lib.const {
            name = "taskwarrior-tui-vendor.tar.gz";
            inherit src;
            outputHash = "sha256-jtVUXWVrBq6xS4y9HKz+JtXHc6LvIk0cC7xmiPB1+ro=";
          }
        );
      }));
    };
    myOptions.socials.enable = true;

    home.packages = with pkgs; [
      comfyuiPackages.krita-with-extensions
    ];
  };
}
