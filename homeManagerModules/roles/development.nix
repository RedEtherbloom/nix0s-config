{
  config,
  lib,
  osConfig,
  pkgs,
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
      default = false;
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
    reverseEngineering = lib.mkOption {
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
    jj = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Jj and accompanying defaults.";
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
    vibecoding = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Trying out some slop coding. Probably won't be used much";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = with pkgs;
          [just]
          ++ lib.optionals cfg.rust [
            clang
            clang-tools
            pkg-config
            # (fenix.complete.withComponents [
            #   "cargo"
            #   "clippy"
            #   "rust-src"
            #   "rustc"
            #   "rustfmt"
            # ])
            # rust-analyzer-nightly
            rustup
          ]
          ++ lib.optionals cfg.openscad [
            openscad-unstable
          ]
          ++ lib.optionals cfg.nix (
            with lixPackageSets.latest;
              [
                nixos-rebuild-ng
                nix-fast-build
                nix-direnv
                nix-init
                nix-update
                nixos-anywhere
                colmena
                nixpkgs-review
                nix-eval-jobs
                nix-du
              ]
              ++ (
                with pkgs; [
                  alejandra
                  nh
                  nixd
                  direnv
                  nix-prefetch-scripts
                  nix-prefetch-github
                  nix-tree
                ]
              )
          )
          # ++ lib.optionals cfg.nix self.devShells.${system}.default.buildInputs
          ++ lib.optionals cfg.electronics [
            kicad-small
          ]
          ++ lib.optionals cfg.three-d-printing [
            prusa-slicer
          ]
          ++ lib.optionals cfg.reverseEngineering [
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
            git-lfs
            git-xet
            git-filter-repo
          ]
          ++ lib.optionals cfg.mcu [
            esphome
            platformio
            esptool
            espflash
            probe-rs-tools
          ]
          ++ lib.optionals cfg.vibecoding [
            antigravity-fhs
          ];

        programs.go.enable = cfg.go;
      }
      (lib.mkIf cfg.git {
        programs = {
          git = {
            enable = true;
            settings = {
              user = {
                name = "RedEtherbloom";
                email = "etherbloom@mailbox.org";
              };
              push.autoSetupRemote = true;
            };
          };
          lazygit = {
            enable = true;
            settings.git.overrideGpg = true;
          };
        };
      })
      (lib.mkIf cfg.github {
        programs = {
          gh-dash.enable = true;
          gh.enable = true;
        };
      })
      (lib.mkIf cfg.jj {
        programs = {
          jjui = {
            enable = true;
          };
          jujutsu = {
            enable = true;
            settings.user = {
              name = "RedEtherbloom";
              email = "etherbloom@mailbox.org";
            };
          };
        };
        home.packages = with pkgs; [
          lazyjj
          jj-fzf
        ];
      })
      (lib.mkIf cfg.java {
        programs.java = {
          enable = true;
          package = pkgs.jdk25;
        };
      })
      (lib.mkIf cfg.direnv {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        systemd.user = {
          services.gcNixDirenv = {
            Unit.Description = "Clean up stale or old nix-direnv shells. Script by DrRuhe.";
            Service = let
              gcNixDirenv = pkgs.writers.writeNu "gcNixDirenv" ''
                use std log

                def nixStoreGetDevshellGcRoots [] {
                    return (nix-store --gc --print-roots |
                        lines |
                        parse "{loc} -> {storepath}" |
                        insert dir {|gcRoot|$gcRoot.loc|parse "{path}/.direnv/{x}" | get -i 0.path} |
                        group-by --to-table dir |
                        rename dir gcRoots |
                        insert modified {|devShell|
                            $devShell.gcRoots|each {|gcRoot|
                                ls -D $gcRoot.loc|get 0.modified
                            }|sort --reverse|first
                        })
                }

                def removeGCRootsFromDevshells [] {
                    let devshells = $in

                    $devshells|each {|devshell|
                        log info $"(ansi red_bold)Removing devshell last modified ($devshell.modified|date humanize): ($devshell.dir) (ansi reset)"
                        direnv revoke $devshell.dir
                        rm -r $"($devshell.dir)/.direnv"
                    }

                    return
                }


                def main [--delete-older-than : duration = 31day] {
                    nixStoreGetDevshellGcRoots|where modified < ((date now) - $delete_older_than)|removeGCRootsFromDevshells
                }
              '';
            in {
              Type = "exec";
              ExecStart = "${gcNixDirenv} --delete-older-than 7day";
            };
          };
          timers.gcNixDirenv = {
            Timer = {
              Unit = "gcNixDirenv.service";
              OnCalendar = "weekly";
              Persistent = true;
            };
          };
        };
      })
      (lib.mkIf osConfig.security.ownAdditional.yubikey {
        programs.git = {
          signing = {
            format = "openpgp";
            key = "341EB1EADB36EC0AC809FBE7BA719C19A950A2F3";
            signByDefault = lib.mkDefault false;
          };
        };
      })
    ]
  );
}
