{
  config,
  secrets,
  ...
}: {
  # TODO: Reread secrets managment with yaml
  sops.secrets."resticPassword" = {
    format = "binary";
    sopsFile = "${secrets}/secrets/fractor/restic/resticPassword";
  };
  sops.secrets."resticRestOptions" = {
    format = "binary";
    sopsFile = "${secrets}/secrets/fractor/restic/restTransportPassword";
  };
  sops.secrets."resticExcludeFile" = {
    format = "binary";
    sopsFile = "${secrets}/secrets/fractor/restic/backup.exclude";
  };
  services.restic.backups."root" = {
    timerConfig = {
      OnCalendar = "wednesday,friday,sunday 22:00";
      Persistent = true;
    };
    # TODO: Reference neurodrive port
    # TODO: I need some proper deployment managment, not just a self-built system(e.g. NixOPS?)
    repository = "rest:https://10.69.0.3:8193/infinity-fractor/";
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
      # TODO: Redundant with central CA?
      # --cacert ${config.sops.secrets."restic_server/public_certificate".path}"
    ];
    environmentFile = config.sops.secrets."resticRestOptions".path;
    createWrapper = true;
    # TODO: Write script that blocks if the wifi is a hotspot
    #backupPrepareCommand = ;
  };
}
