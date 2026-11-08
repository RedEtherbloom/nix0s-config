{
  flake.nixosModules.hibernate = {
    boot.kernelParams = [
      "secretmem.enable=0" # Secretmem inhibits hibernate. Some programs, e.g. bitwarden-desktop, use secretmem if available.
    ];
  };
}
