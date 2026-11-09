{
  flake.nixosModules.zswap = {
    # Taken from Matthew Brunelle: https://blog.matthewbrunelle.com/swap-zram-zswap-and-hibernate-on-nixos/
    boot = {
      kernel.sysctl."vm.swappiness" = 100; # Reduce swapping to SSD
      zswap.enable = true;
    };
  };
}
