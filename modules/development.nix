{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.myOptions.development;
in
{
  options.myOptions.development = {
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
  };

  config = {
    home-manager.sharedModules = [
      {
        home.packages =
          with pkgs;
          lib.optionals cfg.vscode [
            (vscode-with-extensions.override {
              vscodeExtensions =
                with vscode-extensions;
                [
                  mhutchie.git-graph
                  donjayamanne.githistory
                  eamodio.gitlens
                  ms-vscode-remote.remote-ssh
                  mkhl.direnv
                  streetsidesoftware.code-spell-checker
                  redhat.vscode-yaml
                ]
                ++ lib.optionals cfg.vscode-accessibility [
                  vscode-extensions.oderwat.indent-rainbow
                ]
                ++ lib.optionals cfg.nix [
                  jnoortheen.nix-ide
                  arrterian.nix-env-selector
                ]
                ++ lib.optionals cfg.python [
                  ms-python.python
                  ms-python.flake8
                ]
                ++ lib.optionals cfg.docker [
                  ms-azuretools.vscode-docker
                ]
                ++ lib.optionals cfg.rust [
                  vadimcn.vscode-lldb
                  rust-lang.rust-analyzer
                ]
                ++ lib.optionals cfg.java [
                  vscjava.vscode-java-pack
                ]
                ++ lib.optionals cfg.openscad [
                  antyos.openscad
                ] ++ lib.optionals cfg.github [
                  github.vscode-github-actions
                ];
            })
          ]
          ++ lib.optionals cfg.rust [
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
            nixd
            nil
            direnv
            nix-prefetch-scripts
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
    ];

    programs.java = mkIf cfg.java {
      enable = true;
      package = with pkgs; jdk23;
    };
  };
}
