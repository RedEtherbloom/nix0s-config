{lib, ...}: {
  options.myOptions.roles.gamedev.enable = lib.mkOption {
    description = "Enable systemwide options for gamedev";
    type = lib.types.bool;
    default = false;
  };
}
