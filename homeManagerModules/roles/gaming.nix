{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.gaming;
in {
  options.myOptions.roles.gaming.enable = mkOption {
    description = "Install games";
    type = with types; bool;
    default = osConfig.myOptions.roles.gaming.enable;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mindustry-wayland
      gcs
      byar-launcher
      rimsort
      # Eve: Account for bug: https://fractalsoftworks.com/forum/index.php?topic=30633.0
      (starsector.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.makeWrapper];

        postInstall =
          (oldAttrs.postInstall or "")
          + ''
            wrapProgram "$out/bin/starsector" --set __GL_THREADED_OPTIMIZATIONS 0
          '';
      }))

      dxvk_2
    ];
  };
}
