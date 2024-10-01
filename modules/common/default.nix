{ config, lib, pkgs, inputs, ...} : {
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets."sudoers/optional" = {
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/common/sudoers";
  };  
}  
