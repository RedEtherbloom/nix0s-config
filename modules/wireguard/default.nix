{ config, inputs, lib, ... }:
with lib;
let
  cfg = config.networking.ownWireguard;
  wireguardPeer =
    { IP, publicKey, ... }:
    {
      options = {
        IP = mkOption {
          description = "IPv4 of the wireguard client";
          type = types.singleLineStr;
        };
        # How would I detect a miss-match?
        publicKey = mkOption {
          description = "Public key of the wireguard client";
          type = types.singleLineStr;
        };
      };
    };
  wireguardHost =
    {
      mainIP,
      main,
      unlock,
      ...
    }:
    {
      options = {
        # For easier access
        mainIP = mkOption {
          description = "Main IPv4 without suffix";
          type = types.singleLineStr;
        };
        main = mkOption {
          description = "Main wireguard network";
          type = with types; submodule wireguardPeer;
        };
        unlock = mkOption {
          description = "Network for unlocking wireguard devices on boot";
          type = with types; submodule wireguardPeer;
        };
      };
    };
  generateWireguardHost = lastIPDigit: mainPublicKey: unlockPublicKey: wireguardHost {
    mainIP = generateLastIPDigit mainPrefix lastIPDigit;
    main = generateWireguardPeer mainPrefix lastIPDigit mainPublicKey;
    unlock = generateWireguardPeer unlockPrefix lastIPDigit unlockPublicKey;
  };

  mainPrefix = "10.69.0.";
  unlockPrefix = "10.68.0.";
  generateLastIPDigit = prefix: digit: prefix digit;
  generateWithSuffix =
    prefix: digit: suffix:
    (generateLastIPDigit prefix digit) "/" suffix;
  generateWireguardPeer = prefix: lastIPDigit: publicKey: {
    IP = (generateWithSuffix prefix lastIPDigit "32");
    publicKey = publicKey;
  };
in
{
  options = {
    networking.ownWireguard = {
      enabled = mkEnableOption "Insert own standard wireguard config";
      currentHost = mkOption {
        description = "Current host to be configured";
        type = wireguardHost;
      };
      # To be referenced in other files or services
      # TODO: Rewrite with attrset(I think one can modularize)
      hosts = mkOption {
        description = "Listing of our wireguard hosts for easy cross-reference";
        type = with types; attrsOf (submodule wireguardHost);
        default = {
          wireguardController =
            (generateWireguardHost "1" "d6yoEQMbMy4M4h45sj28RrgKxYZXRxDHAJ5ASRKZMmQ="
              "81mzxX6r5pTzNqeofAA3L/xYmzrjOiBKQ8tuvBAWOR8=");
          fractor = (generateWireguardPeer "2" "" "");
          neurodrive =
            (generateWireguardPeer "3" "kEIYSz20OKCGyWcnXlRBSkWBt7DkjKhmb1Xu+0Kc3XY="
              "3gMbw0t8dlUGUnRmmNJlNM75tKsygjpWYD/1fQaekXg=");
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enabled {
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
          ips = [ cfg.currentHost.main.IP ];
          listenPort = 51820;
          privateKeyFile = config.sops.secrets."wireguard/wg0_private".path;
          peers = [
            {
              publicKey = (cfg.hosts.wireguardController.main.publicKey);
              allowedIPs = [
                (generateWithSuffix mainPrefix "0" "32")
              ];
              endpoint = "51.15.91.213:51820";
              persistentKeepalive = 25;
            }
          ];
        };
        wg1 = {
          ips = [ cfg.currentHost.unlock.IP ];
          listenPort = 51821;
          privateKeyFile = config.sops.secrets."wireguard/wg1_private".path;
          peers = [
            {
              publicKey = (cfg.hosts.wireguardController.unlock.publicKey);
              allowedIPs = [
                (generateWithSuffix unlockPrefix "0" "32")
              ];
              endpoint = "51.15.91.213:51821";
              persistentKeepalive = 25;
            }
          ];
        };
      };

      networking.firewall.allowedUDPPorts = lib.attrsets.mapAttrsToList (
        name: value: value.listenPort
      ) config.networking.wireguard.interfaces;
    })
  ];
}
