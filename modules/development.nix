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
    rust = mkEnableOption "rust toolchain and dev tools";
    java = mkEnableOption "Java and vscode pack";
    python = mkEnableOption "Python(Full) and vscode plugins";
    docker = mkOption {
      type = types.bool;
      default = false;
      description = "Enable docker service and docker vscode plugin";
    };
    nix = mkEnableOption "Enable Nix dev tools and VS-Code plugins";
    openscad = mkEnableOption "OpenSCAD and VS-Code plugin";
    vscode = mkEnableOption "Enable VS-Code and plugins";
    vscode-accessibility = mkEnableOption "Enable VS-Code accesibility plugins";
    electronics = mkEnableOption "Electronics toolchain";
    three-d-printing = mkEnableOption "3d printing toolchain and tools";
    reverse-engineering = mkOption {
      type = types.bool;
      default = false;
      description = "Reverse engineering toolchain";
    };
    network-analysis = mkEnableOption "Toolchain for network analysis";
  };

  config = {
    home-manager.sharedModules = [
      {
        home.packages =
          with pkgs;
          lib.optionals cfg.vscode (
            vscode-with-extensions.override {
              vscodeExtensions =
                with vscode-extensions;
                # TODO: Rewrite with mkIf/mkMerge to make the evaluation lazy(I think)
                [
                  mhutchie.git-graph
                  donjayamanne.githistory
                  eamodio.gitlens
                  ms-vscode-remote.remote-ssh
                  mkhl.direnv
                  streetsidesoftware.code-spell-checker
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
                ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace lib.optionals cfg.openscad [
                  {
                    name = "openscad";
                    publisher = "Antyos";
                    version = "1.3.1";
                    sha256 = "sha256-J4lJgZT0HXRC2B1eFUl4MoP0YT5EZjLPl3yIY+VLBiI=";
                  }
                ];
            }
          )
          ++ lib.optionals cfg.rust [
            rustup
            clang
            clang-tools
          ]
          ++ lib.optionals cfg.openscad [
            openscad-unstable
          ]
          ++ lib.optionals cfg.nix [
            nixfmt-rfc-style
            nixd
            nil
            direnv
          ] ++ lib.optionals cfg.electronics [
            kicad
          ] ++ lib.optionals cfg.three-d-printing [
            prusa-slicer
          ] ++ lib.optionals cfg.reverse-engineering [
            ghidra
          ] ++ lib.optionals cfg.network-analysis [
            nmap
            wireshark
          ];
      }
    ];

    programs.java = mkIf cfg.java {
      enable = true;
      package = with pkgs; jdk22;
    };
  };
}
