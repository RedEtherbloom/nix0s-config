{ config, inputs, pkgs, ... }:
{
  sops.secrets.fritz_box_password = {
    sopsFile = ../"${inputs.our-secrets}/secrets/services/fritz-logger.yaml";
  };

  systemd.user.services.fritz-logger = {
    Unit = {
      Description = "Periodically logs connected fritz box clients to a sqlite database";
      After = [
        "network.target"
        "sops-nix.service"
      ];
    };
    Install = {
      # May need default.target tbh
      # WantedBy = [ "multi-user.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.fritz-logger}/bin/fritz_logger";
      Environment = [
        "IP_ADDRESS=192.168.178.1"
        "PASSWORD_FILE=${config.sops.secrets.fritz_box_password.path}"
        "PRUNE_OLDER_THAN=14"
        "QUERY_PERIOD=${toString (15 * 60)}"
      ];
    };
  };
}
