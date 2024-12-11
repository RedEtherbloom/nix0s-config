{ config, inputs, ...}: {
  sops.secrets.audiosink_crypto_password = {
    sopsFile = "${inputs.our-secrets}/secrets/audiosink/crypto_password.enc";
    format = "binary";
  };
}
