{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.services.gitea;

  # DEFAULT Port, reexported
  GITEA_PORT = 3000;
  GITEA_DOMAIN = config.networking.ownWireguard.hosts.neurodrive.mainIP;
  GITEA_SECRET_DIRECTORY = ../../secrets/services/gitea;
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
          PROTOCOL = "https";
          DOMAIN = GITEA_DOMAIN;
          HTTP_PORT = GITEA_PORT;
          CERT_FILE = (builtins.toString ../../secrets/services/gitea/gitea.crt);
          KEY_FILE = config.sops.secrets."gitea/gitea.key".path;
        };
      };
      lfs.enable = true;
      database = {
        createDatabase = true;
        passwordFile = config.sops.secrets."gitea/database_password".path;
      };
    };
  };
}
