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
  lazygitCommandWindow = name: location:
    pkgs.writeShellApplication {
      name = "lazygit${name}.sh";
      runtimeInputs = [
        config.programs.kitty.package
        pkgs.libnotify
      ];
      text = ''
        kitty zsh -c "cd ${location} && git pull && notify-send \"Sync worked without problem for location $(basename ${location})\" --expire-time=2000 || lazygit"
      '';
    };
in {
  xdg.dataFile."${builtins.baseNameOf own-hm-data-directory}/.keep".text = "";

  inherit data-server-ip wgIpOrLocalhost own-hm-data-directory lazygitCommandWindow;
}
