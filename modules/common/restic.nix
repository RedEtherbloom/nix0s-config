{ ... }: {
  sops.secrets."restic_server/public_certificate" = {
    format = "binary";
    sopsFile = ../../secrets/neurodrive/restic_server/certificate.pub;
  };
}