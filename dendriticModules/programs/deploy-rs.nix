{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.deploy-rs = {
    config,
    pkgs,
    ...
  }: {
  };
}
