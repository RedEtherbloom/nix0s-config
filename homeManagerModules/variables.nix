{ config, osConfig, ... }:
let
  data-server-ip =
    if
      (osConfig.networking.ownWireguard.currentHost.mainIP == osConfig.networking.ownWireguard.hosts.neurodrive.mainIP)
    then
      "localhost"
    else
      osConfig.networking.ownWireguard.hosts.neurodrive.mainIP;
  own-hm-data-directory = "${config.xdg.dataHome}/data-for-home-manager";
in
{
  xdg.dataFile."${builtins.baseNameOf own-hm-data-directory}/.keep".text = "";

  inherit data-server-ip own-hm-data-directory;
}
