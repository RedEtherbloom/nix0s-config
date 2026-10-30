{self, ...}: {
  flake = {
    nixosModules.fractor-restic = {
      config,
      secrets,
      ...
    }: {
      sops.secrets = {
        "resticPassword" = {
          format = "binary";
          sopsFile = "${secrets}/secrets/fractor/restic/resticPassword";
        };
        "resticRestOptions" = {
          format = "binary";
          sopsFile = "${secrets}/secrets/fractor/restic/restTransportPassword";
        };
        "resticExcludeFile" = {
          format = "binary";
          sopsFile = "${secrets}/secrets/fractor/restic/backup.exclude";
        };
      };
      services.restic.backups."root" = {
        timerConfig = {
          OnCalendar = "wednesday,friday,sunday 22:00";
          Persistent = true;
        };
        repository = "rest:https://${self.deploy.nodes.neurodrive.hostname}:${toString self.nixosConfigurations.neurodrive.config.services.restic.server.port}/infinity-fractor/";
        pruneOpts = [
          "--keep-daily 3"
          "--keep-weekly 5"
          "--keep-monthly 10"
          "--keep-yearly 50"
        ];
        paths = ["/"];
        passwordFile = config.sops.secrets."resticPassword".path;
        inhibitsSleep = true;
        extraBackupArgs = [
          "--exclude-caches"
          "--exclude-file ${config.sops.secrets.resticExcludeFile.path}"
        ];
        extraOptions = [
          "local.layout='autodetect'"
          # --cacert ${config.sops.secrets."restic_server/public_certificate".path}"
        ];
        environmentFile = config.sops.secrets."resticRestOptions".path;
        createWrapper = true;
        # TODO: Write script that blocks if the wifi is a hotspot
        #backupPrepareCommand = ;
      };
    };
  };
}
