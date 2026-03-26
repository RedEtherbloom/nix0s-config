{
  config,
  secrets,
  ...
}: let
  functions = import ./common/functions.nix {inherit config;};
  taskwarrior_secrets = "${secrets}/secrets/services/taskwarrior.yaml";
in {
  sops = {
    secrets = {
      encryption_secret.sopsFile = taskwarrior_secrets;
      client_id.sopsFile = taskwarrior_secrets;
    };
    templates."taskwarrior-sync.rc" = {
      owner = "inf";
      content = ''
        sync.encryption_secret = ${config.sops.placeholder.encryption_secret}
        sync.server.client_id = ${config.sops.placeholder.client_id}
        sync.server.url = http://${functions.data-server-ip}:${toString config.myOptions.services.taskchampion.taskchampionPort}
      '';
    };
  };
}
