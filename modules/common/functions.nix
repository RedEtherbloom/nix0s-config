# Duplicated from variables.nix
# TODO: Merge those two
{ config }: let
  data-server-ip =
    wgIpOrLocalhost config.networking.ownWireguard.neurodrive;
  wgIpOrLocalhost =
    wireguardHost:
    if
      (
        config.networking.ownWireguard.currentHost.mainIP
        == wireguardHost.mainIP
      )
    then
      "localhost"
    else
      wireguardHost.mainIP;
in {
  inherit data-server-ip wgIpOrLocalhost;
}