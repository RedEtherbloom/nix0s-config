{ config, inputs, lib, ... }:
with lib;
let
  cfg = config.networking.ownWireguard;
in
{
  options = {
    networking.ownWireguard = {
      enabled = mkEnableOption "Insert own standard wireguard config";
      lastIPDigit = mkOption {
        type = types.ints.u8;
        description = "Last digit in IPv4 to use for client";
      };
    };
  };

  config = mkIf cfg.enabled {
    sops.secrets."wireguard/wg0_private" = {
      format = "binary";
      sopsFile = "${inputs.our-secrets}/secrets/${config.networking.hostName}/wireguard/wg0.priv";
    };  
    sops.secrets."wireguard/wg1_private" = {
      format = "binary";
      sopsFile = "${inputs.our-secrets}/secrets/${config.networking.hostName}/wireguard/wg1.priv";
    };  

    networking.wireguard.interfaces = {
      wg0 = {
        ips = [ ("10.69.0." + toString cfg.lastIPDigit + "/32") ];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets."wireguard/wg0_private".path;
        peers = [
          {
            publicKey = "d6yoEQMbMy4M4h45sj28RrgKxYZXRxDHAJ5ASRKZMmQ=";
            allowedIPs = [ "10.69.0.0/24" ];
            endpoint = "51.15.91.213:51820";
            persistentKeepalive = 25;
          }
        ];
      };
      wg1 = {
        ips = [ ("10.68.0." + toString cfg.lastIPDigit + "/32") ];
        listenPort = 51821;
        privateKeyFile = config.sops.secrets."wireguard/wg1_private".path;
        peers = [
          {
            publicKey = "81mzxX6r5pTzNqeofAA3L/xYmzrjOiBKQ8tuvBAWOR8=";
            allowedIPs = [ "10.68.0.0/24" ];
            endpoint = "51.15.91.213:51821";
            persistentKeepalive = 25;
          }
        ];
      };
    };

    networking.firewall.allowedUDPPorts = lib.attrsets.mapAttrsToList (
      name: value: value.listenPort
    ) config.networking.wireguard.interfaces;
  };
}
