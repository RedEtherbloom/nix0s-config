{
  config,
  inputs,
  osConfig,
  ...
}:
{
  # TODO: How do I group these?
  sops.secrets.encryption_secret = {
    sopsFile = "${inputs.our-secrets}/secrets/services/taskwarrior.yaml";
  };
  sops.secrets.client_id = {
    sopsFile = "${inputs.our-secrets}/secrets/services/taskwarrior.yaml";
  };

  services.taskwarrior-sync.enable = true;

  programs.taskwarrior = {
    enable = true;
    config = {
      # TODO: Insert taskrc from fractor
      sync = {
        encryption_secret = "!${config.sops.secrets.encryption_secret.path}";
        server = {
          url = with osConfig.myOptions.taskchampion; "http://${taskchampionIP}:${toString taskchampionPort}";
          client_id = "!${config.sops.secrets.client_id.path}";
        };
      };
    };
  };
}
