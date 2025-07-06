{
  config,
  lib,
  osConfig,
  pkgs,
  self,
  system,
  ...
}: let
  cfg = config.myOptions.roles.development;
in {
  options.myOptions.roles.development = {
    enable = lib.mkOption {
      type = with lib.types; bool;
      default = false;
      description = "Enable development modules.";
    };
    rust = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Rust toolchain and dev tools.";
    };
    java = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Java and vscode pack.";
    };
    python = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Python tooling and vscode plugins.";
    };
    docker = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable docker service and docker vscode plugin.";
    };
    nix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Nix dev tools and VS-Code plugins.";
    };
    openscad = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "OpenSCAD and VS-Code plugin.";
    };
    vscode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable VS-Code and plugins.";
    };
    vscode-accessibility = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable VS-Code accesibility plugins.";
    };
    electronics = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Electronics toolchain.";
    };
    three-d-printing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "3d printing toolchain and tools.";
    };
    reverse-engineering = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Reverse engineering toolchain.";
    };
    network-analysis = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Toolchain for network analysis.";
    };
    git = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Git and accompanying defaults.";
    };
    github = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Useful extensions and tools for github.";
    };
    copilot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the Github Copilot extension.";
    };
    direnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable direnv.";
    };
    go = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable go.";
    };
    mcu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCU tools.";
    };
    cursor = lib.mkOption {
      description = "Enable cursor IDE.";
      type = lib.types.bool;
      default = true;
    };
    # I'm getting fed up with our half-baked nvim config.
    helix = lib.mkOption {
      description = "Enable helix IDE.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = with pkgs;
        lib.optionals cfg.rust [
          rustup
          clang
          clang-tools
        ]
        ++ lib.optionals cfg.openscad [
          openscad
        ]
        ++ lib.optionals cfg.nix self.devShell.${system}
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
        ]
        ++ lib.optionals cfg.cursor [
          code-cursor
        ];
    }
    (lib.mkIf cfg.git {
      programs.git = {
        enable = true;
        extraConfig = {
          push = {
            autoSetupRemote = true;
          };
        };
      };
    })
    (lib.mkIf cfg.github {
      programs = {
        gh-dash.enable = true;
        gh.enable = true;
      };
    })
    (lib.mkIf cfg.java {
      programs.java = {
        enable = true;
        package = with pkgs; jdk23;
      };
    })
    (lib.mkIf cfg.direnv {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    })
    (lib.mkIf cfg.go {
      programs.go.enable = true;
    })
    (lib.mkIf osConfig.security.ownAdditional.yubikey {
      # TODO: Maybe merge with github config
      programs.git = {
        userEmail = "etherbloom@mailbox.org";
        signing = {
          format = "openpgp";
          # TODO: Turn into it's own global variable
          key = "341EB1EADB36EC0AC809FBE7BA719C19A950A2F3";
          signByDefault = lib.mkDefault true;
        };
      };
    })
    (lib.mkIf cfg.helix {
      programs.helix.enable = true;
    })
  ]);
}
