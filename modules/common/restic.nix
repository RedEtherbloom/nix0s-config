{ inputs, ... }: {
  sops.secrets."restic_server/public_certificate" = {
    mode = "0444";
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/neurodrive/restic_server/certificate.pub";
  };
}
