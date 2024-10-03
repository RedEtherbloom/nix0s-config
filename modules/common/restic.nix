{ inputs, ... }: {
  sops.secrets."restic_server/public_certificate" = {
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/neurodrive/restic_server/certificate.pub";
  };
}
