{pkgs ? import <nixpkgs> {}}: (pkgs.writers.writePython3Bin "fritz_logger" {
    libraries = [
      pkgs.sqlite
      pkgs.python3Packages.fritzconnection
      pkgs.python3Packages.platformdirs
    ];
    flakeIgnore = [
      "E265"
    ];
  }
  ./fritz-logger.py)
