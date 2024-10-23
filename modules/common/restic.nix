{ ... }:
{
  sops.secrets."restic_server/public_certificate" = {
    mode = "0444";
    format = "binary";
    sopsFile = ../../secrets/neurodrive/restic_server/certificate.pub;
  };
}
