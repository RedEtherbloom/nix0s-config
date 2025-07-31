{secrets, ...}: {
  sops.secrets.audiosink_crypto_password = {
    sopsFile = "${secrets}/secrets/audiosink/crypto_password.enc";
    format = "binary";
  };
}
