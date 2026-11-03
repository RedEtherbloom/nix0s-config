{
  flake.nixosModules.deploy = {secrets, ...}: {
    users.users."root".openssh.authorizedKeys.keyFiles = [
      "${secrets}/secrets/neural-augmenter/main_deploy_key.pub"
    ];
  };
}
