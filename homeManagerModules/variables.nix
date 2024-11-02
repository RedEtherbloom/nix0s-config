{ config, osConfig, ... }:
let
  data-server-ip =
    wgIpOrLocalhost osConfig.networking.ownWireguard.neurodrive;
  wgIpOrLocalhost =
    wireguardHost:
    if
      (
        osConfig.networking.ownWireguard.currentHost.mainIP
        == wireguardHost.mainIP
      )
    then
      "localhost"
    else
      wireguardHost.mainIP;
  own-hm-data-directory = "${config.xdg.dataHome}/data-for-home-manager";
in
{
  xdg.dataFile."${builtins.baseNameOf own-hm-data-directory}/.keep".text = "";

  inherit data-server-ip wgIpOrLocalhost own-hm-data-directory;
}
