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

  sops.secrets."spotify/username" = {
    key = "Username";
    sopsFile = "${inputs.our-secrets}/secrets/audiosink/spotify.yaml";
  };
  services.librespot = let
    librespot-wrapped = pkgs.writeShellScriptBin "librespot" ''
      export USERNAME="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."spotify/username".path})"
      ${pkgs.librespot}/bin/librespot $@
    '';
  in {
    enable = true;
    package = librespot-wrapped;
    settings = {
      "name" = "audio_pi";
      "device-type" = "speaker";
      "enable-oauth" = true;
      # Headless login
      "oauth-port" = 0;
      "zeroconf-port" = 5566;
    };
  };
}
