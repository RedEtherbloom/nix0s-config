{
  config,
  osConfig,
  pkgs,
  ...
}: let
  data-server-ip = wgIpOrLocalhost osConfig.networking.ownWireguard.hosts.neurodrive;
  wgIpOrLocalhost = wireguardHost:
    if (osConfig.networking.ownWireguard.currentHost.mainIP == wireguardHost.mainIP)
    then "localhost"
    else wireguardHost.mainIP;
  own-hm-data-directory = "${config.xdg.dataHome}/data-for-home-manager";
  lazygitCommandWindow = name: location: let
    command = pkgs.writeShellScriptBin "commandWindow-lazygit-${name}.sh" ''
      set -e
      kitty zsh -c "cd ${location} && git pull && exit || lazygit"
    '';
  in "${command}";
in {
  xdg.dataFile."${builtins.baseNameOf own-hm-data-directory}/.keep".text = "";

  inherit data-server-ip wgIpOrLocalhost own-hm-data-directory lazygitCommandWindow;
}
