{
  config,
  inputs,
  osConfig,
  ...
}:
let
  taskwarrior_secrets = "${inputs.our-secrets}/secrets/services/taskwarrior.yaml";
in
{
  # TODO: How do I group these?
  sops.secrets.encryption_secret = {
    sopsFile = "${inputs.our-secrets}/secrets/services/taskwarrior.yaml";
  };
  sops.secrets.client_id = {
    sopsFile = "${inputs.our-secrets}/secrets/services/taskwarrior.yaml";
  };

  # TODO: Can other users read this by default as well? I hope not
  sops.templates."taskwarrior-sync.rc".content = ''
    sync.encryption_secret = "${config.sops.placeholder.encryption_secret}"
    sync.server.client_id = "${config.sops.placeholder.client_id}""
    sync.server.url = "http://${osConfig.myOptions.taskchampion.taskchampionIP}:${toString osConfig.myOptions.taskchampion.taskchampionPort}"
  '';

  services.taskwarrior-sync.enable = true;

  programs.taskwarrior = {
    enable = true;
    extraConfig = ''
      include ${config.sops.templates."taskwarrior-sync.rc".path}
    '';
  };
}
