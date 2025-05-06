{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.stateVersion = "25.05";
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  xdg.configFile."pulse/cookie" = {
    enable = true;
    source = "${inputs.our-secrets}/secrets/common/pulse_cookie";
  };

  services.librespot = {
    enable = true;
    package = pkgs.librespot;
    settings = {
      "name" = "spotify_pi";
      "device-type" = "speaker";
      "enable-oauth" = true;
      # Headless login
      "oauth-port" = 0;
    };
  };
}
