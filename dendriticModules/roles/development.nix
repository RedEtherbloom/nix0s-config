{
  # TODO: Split out into seperate e.g. language modules
  flake.homeModules.development = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    cfg = config.myOptions.roles.development;
  in {
    options.myOptions.roles.development = {
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
      fren-coding = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "A fren shared with us :3.";
      };
    };

    config = (
      lib.mkMerge [
        {
          home.packages =
            [
              pkgs.just
              pkgs.godot
              # renderdoc # Debugging render scenes for Minecraft
            ]
            ++ lib.optionals cfg.rust [
              pkgs.clang
              pkgs.clang-tools
              pkgs.pkg-config
              pkgs.rustup
            ]
            ++ lib.optionals cfg.openscad [
              pkgs.openscad-unstable
            ]
            # IDEA: Reference main dev-shell
            ++ lib.optionals cfg.nix (
              [
                pkgs.lixPackageSets.latest.nixos-rebuild-ng
                pkgs.lixPackageSets.latest.nix-fast-build
                pkgs.lixPackageSets.latest.nix-direnv
                pkgs.lixPackageSets.latest.nix-init
                pkgs.lixPackageSets.latest.nix-update
                pkgs.lixPackageSets.latest.nixos-anywhere
                pkgs.lixPackageSets.latest.colmena
                pkgs.lixPackageSets.latest.nixpkgs-review
                pkgs.lixPackageSets.latest.nix-eval-jobs
                pkgs.lixPackageSets.latest.nix-du
                pkgs.lixPackageSets.latest.nurl
              ]
              ++ [
                pkgs.alejandra
                pkgs.nixd
                pkgs.direnv
                pkgs.nix-tree
              ]
            )
            ++ lib.optionals cfg.electronics [
              pkgs.kicad-small
            ]
            ++ lib.optionals cfg.three-d-printing [
              pkgs.prusa-slicer
            ]
            ++ lib.optionals cfg.reverseEngineering [
              pkgs.ghidra
            ]
            ++ lib.optionals cfg.network-analysis [
              pkgs.nmap
              pkgs.wireshark
            ]
            ++ lib.optionals cfg.python [
              pkgs.python3Packages.flake8
            ]
            ++ lib.optionals cfg.git [
              pkgs.git
              pkgs.git-lfs
              pkgs.git-xet
              pkgs.git-filter-repo
            ]
            ++ lib.optionals cfg.mcu [
              pkgs.esphome
              pkgs.platformio
              pkgs.esptool
              pkgs.espflash
              pkgs.probe-rs-tools
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
          home.packages = [
            pkgs.lazyjj
            pkgs.jj-fzf
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
        (lib.mkIf cfg.fren-coding {
          programs.pi-coding-agent.enable = true;
          home.file.".pi/agent/models.json".text = builtins.toJSON {
            providers.astarion-litellm = {
              baseUrl = "http://100.74.165.55:4000/v1";
              apiKey = "not-needed";
              api = "openai-responses";

              models = [
                {
                  id = "chatgpt-gpt-5.5";
                  name = "GPT-5.5 via astarion";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 272000;
                  maxTokens = 128000;
                }
                {
                  id = "chatgpt-gpt-5.5-pro";
                  name = "GPT-5.5 Pro via astarion";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 272000;
                  maxTokens = 128000;
                }
                {
                  id = "chatgpt-gpt-5.3-codex-spark";
                  name = "GPT-5.3 Codex Spark via astarion";
                  reasoning = true;
                  input = ["text"];
                  contextWindow = 128000;
                  maxTokens = 128000;
                }
                {
                  id = "chatgpt-gpt-5.6-sol";
                  name = "GPT-5.6 Sol via astarion";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 272000;
                  maxTokens = 128000;
                }
                {
                  id = "chatgpt-gpt-5.6-terra";
                  name = "GPT-5.6 Terra via astarion";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 272000;
                  maxTokens = 128000;
                }
                {
                  id = "chatgpt-gpt-5.6-luna";
                  name = "GPT-5.6 Luna via astarion";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 272000;
                  maxTokens = 128000;
                }
              ];
            };
          };
        })
      ]
    );
  };
}
