{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.development;
in {
  options.myOptions.roles.development = {
    enable = mkOption {
      description = "Enable development modules";
      type = with types; bool;
      default = false;
    };
    rust = mkOption {
      type = types.bool;
      default = true;
      description = "rust toolchain and dev tools";
    };
    java = mkOption {
      type = types.bool;
      default = true;
      description = "Java and vscode pack";
    };
    python = mkOption {
      type = types.bool;
      default = true;
      description = "Python tooling and vscode plugins";
    };
    docker = mkOption {
      type = types.bool;
      default = false;
      description = "Enable docker service and docker vscode plugin";
    };
    nix = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Nix dev tools and VS-Code plugins";
    };
    openscad = mkOption {
      type = types.bool;
      default = true;
      description = "OpenSCAD and VS-Code plugin";
    };
    vscode = mkOption {
      type = types.bool;
      default = true;
      description = "Enable VS-Code and plugins";
    };
    vscode-accessibility = mkOption {
      type = types.bool;
      default = true;
      description = "Enable VS-Code accesibility plugins";
    };
    electronics = mkOption {
      type = types.bool;
      default = false;
      description = "Electronics toolchain";
    };
    three-d-printing = mkOption {
      type = types.bool;
      default = true;
      description = "3d printing toolchain and tools";
    };
    reverse-engineering = mkOption {
      type = types.bool;
      default = false;
      description = "Reverse engineering toolchain";
    };
    network-analysis = mkOption {
      type = types.bool;
      default = true;
      description = "Toolchain for network analysis";
    };
    git = mkOption {
      type = types.bool;
      default = true;
      description = "Git and accompanying defaults";
    };
    github = mkOption {
      type = types.bool;
      default = true;
      description = "Useful extensions and tools for github";
    };
    copilot = mkOption {
      type = types.bool;
      default = true;
      description = "Install the Github Copilot extension";
    };
    direnv = mkOption {
      type = types.bool;
      default = true;
      description = "Install direnv";
    };
    go = mkOption {
      description = "Enable go";
      type = types.bool;
      default = true;
    };
    mcu = mkOption {
      description = "Enable MCU tools";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs;
        lib.optionals cfg.rust [
          rustup
          clang
          clang-tools
        ]
        ++ lib.optionals cfg.openscad [
          openscad-unstable
        ]
        # TODO: Merge with DevShell
        ++ lib.optionals cfg.nix [
          nixfmt-rfc-style
          alejandra
          nh
          nil
          direnv
          nix-prefetch-scripts
          nix-tree
        ]
        ++ lib.optionals cfg.electronics [
          kicad
        ]
        ++ lib.optionals cfg.three-d-printing [
          prusa-slicer
        ]
        ++ lib.optionals cfg.reverse-engineering [
          ghidra
        ]
        ++ lib.optionals cfg.network-analysis [
          nmap
          wireshark
        ]
        ++ lib.optionals cfg.python [
          python3Packages.flake8
        ]
        ++ lib.optionals cfg.git [
          git
          lazygit
          git-lfs
          git-filter-repo
        ]
        ++ lib.optionals cfg.mcu [
          esphome
          esptool
          platformio
          arduino-ide
          arduino-cli
          arduinoOTA
        ];
    }
    (mkIf cfg.git {
      programs.git = {
        enable = true;
        extraConfig = {
          push = {
            autoSetupRemote = true;
          };
        };
      };
    })
    (mkIf cfg.github {
      programs.gh.enable = true;
    })
    (mkIf cfg.java {
      programs.java = {
        enable = true;
        package = with pkgs; jdk23;
      };
    })
    (mkIf cfg.direnv {
      # TODO: Cassea: Maybe use nix-direnv, the gcroot feature may be good or bad, depending on disk cache
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    })
    (mkIf cfg.go {
      programs.go.enable = true;
    })
  ]);
}
