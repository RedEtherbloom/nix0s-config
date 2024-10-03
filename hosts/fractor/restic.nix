{ config, inputs, ... }: {
  # TODO: Reread secrets managment with yaml
  sops.secrets."resticPassword" = {
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/fractor/restic/resticPassword";
  };
  sops.secrets."resticRestOptions" = {
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/fractor/restic/restTransportPassword";
  };
  sops.secrets."resticExcludeFile" = {
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/fractor/restic/backup.exclude";
  };
  services.restic.backups."root" = {
    timerConfig = {
      OnCalendar = "wednesday, friday, sunday 22:00";
      Persistent = true;
    };
    # TODO: Generate Certfile and rollout #security
    # TODO: Reference neurodrive port
    repository = "rest:http://192.168.178.56:8193/infinity-fractor/";
    pruneOpts = [
      "--keep-daily 3"
      "--keep-weekly 5"
      "--keep-monthly 10"
      "--keep-yearly 50"
    ];
    paths = [ "/" ];
    passwordFile = config.sops.secrets."resticPassword".path;
    inhibitsSleep = true;
    extraBackupArgs = [
      "--exclude-caches"
      "--exclude-file ${config.sops.secrets.resticExcludeFile.path}"
    ];
    environmentFile = config.sops.secrets."resticRestOptions".path;
    createWrapper = true;
    # TODO: Write script that blocks if the wifi is a hotspot
    #backupPrepareCommand = ;
  };
}
