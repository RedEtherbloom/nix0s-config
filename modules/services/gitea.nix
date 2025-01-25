{
  config,
  inputs,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.services.gitea;

  # DEFAULT Port, reexported
  GITEA_PORT = 3000;
  GITEA_DOMAIN = config.networking.ownWireguard.hosts.neurodrive.mainIP;
  GITEA_SECRET_DIRECTORY = "${inputs.our-secrets}/secrets/services/gitea";
  GITEA_SECRET_FILE = "${GITEA_SECRET_DIRECTORY}/gitea.yaml";
in {
  options.myOptions.services.gitea = {
    enable = mkOption {
      description = "Enable gitea";
      type = with types; bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."gitea/database_password" = {
      sopsFile = GITEA_SECRET_FILE;
      owner = config.services.gitea.user;
      group = config.services.gitea.group;
    };
    sops.secrets."gitea/gitea.key" = {
      sopsFile = "${GITEA_SECRET_DIRECTORY}/gitea.key";
      format = "binary";
      restartUnits = ["gitea.service"];
      owner = config.services.gitea.user;
      group = config.services.gitea.group;
    };

    services.gitea = {
      enable = true;
      settings = {
        server = {
          PROTOCOL = "http";
          DOMAIN = GITEA_DOMAIN;
          HTTP_PORT = GITEA_PORT;
          CERT_FILE = builtins.toString "${inputs.our-secrets}/secrets/services/gitea/gitea.crt)";
          KEY_FILE = config.sops.secrets."gitea/gitea.key".path;
        };
        repository = {
          DEFAULT_PRIVATE = "private";
          DEFAULT_PUSH_CREATE_PRIVATE = true;

          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG = true;
        };
      };
      lfs.enable = true;
      database = {
        createDatabase = true;
        passwordFile = config.sops.secrets."gitea/database_password".path;
      };
    };

    networking.firewall.interfaces."wg0".allowedTCPPorts = [GITEA_PORT];
    networking.firewall.interfaces."wg0".allowedUDPPorts = [GITEA_PORT];
  };
}
