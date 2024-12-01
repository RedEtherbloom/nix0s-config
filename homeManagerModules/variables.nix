{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  data-server-ip = wgIpOrLocalhost osConfig.networking.ownWireguard.hosts.neurodrive;
  wgIpOrLocalhost = wireguardHost:
    if (osConfig.networking.ownWireguard.currentHost.mainIP == wireguardHost.mainIP)
    then "localhost"
    else wireguardHost.mainIP;
  own-hm-data-directory = "${config.xdg.dataHome}/data-for-home-manager";

  autostartApplicationFromBinary = {
    name,
    exec,
    extraExecArgs ? "",
  }: let
    lowerCase = strings.toLower name;
    out = pkgs.makeDesktopItem {
      inherit name;
      desktopName = name;
      icon = lowerCase;
      exec = "${exec} ${extraExecArgs}";
    };
  in {
    xdg.configFile."autostart/${name}.desktop".source = "${out}/share/applications/${name}.desktop";
  };

  autostartApplicationFromPackage = {
    package,
    extraExecArgs ? "",
  }: let
    out = package.desktopItem.override (prev: {exec = prev.exec + extraExecArgs;});
  in {
    xdg.configFile."autostart" = {
      source = "${out}/share/applications/";
      recursive = true;
    };
  };

  lazygitCommandWindow = name: location: let
    command = pkgs.writeShellScriptBin "commandWindow-lazygit-${name}.sh" ''
      set -e
      kitty zsh -c "cd ${location} && git pull && exit || lazygit"
    '';
  in "${command}";
in {
  xdg.dataFile."${builtins.baseNameOf own-hm-data-directory}/.keep".text = "";

  inherit autostartApplicationFromBinary autostartApplicationFromPackage data-server-ip wgIpOrLocalhost own-hm-data-directory lazygitCommandWindow;
}
