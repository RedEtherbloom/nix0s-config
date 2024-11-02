# TODO: Move to home-managr once it supports sops-nix templates
{ config, ... }:
let
  functions = import ./functions.nix { inherit config; };
  taskwarrior_secrets = ../../secrets/services/taskwarrior.yaml;
in
{
  # TODO: How do I group these?
  sops.secrets.encryption_secret = {
    sopsFile = taskwarrior_secrets;
  };
  sops.secrets.client_id = {
    sopsFile = taskwarrior_secrets;
  };

  # TODO: Can other users read this by default as well? I hope not
  # TODO: Use vars.data-server-ip once we have refactored variables.nix
  sops.templates."taskwarrior-sync.rc" = {
    owner = "inf";
    content = ''
    sync.encryption_secret = "${config.sops.placeholder.encryption_secret}"
    sync.server.client_id = "${config.sops.placeholder.client_id}" 
    sync.server.url = "http://${functions.data-server-ip}:${toString config.myOptions.services.taskchampion.taskchampionPort}"
  '';
  };
}
