{ config, lib, ... }:
with lib;
let
  cfg = config.networking.ownWireguard;

  mainPrefix = "10.69.0.";
  unlockPrefix = "10.68.0.";

  wireguardPeer =
    { ... }:
    {
      options = {
        IP = mkOption {
          description = "IPv4 of the wireguard client";
          type = with types; str;
        };
        # How would I detect a miss-match?
        publicKey = mkOption {
          description = "Public key of the wireguard client";
          type = with types; str;
        };
      };
    };
  wireguardHost =
    { ... }:
    {
      options = {
        # For easier access
        mainIP = mkOption {
          description = "Main IPv4 without suffix";
          type = with types; str;
        };
        main = mkOption {
          description = "Main wireguard network";
          type = with types; (submodule wireguardPeer);
        };
        unlock = mkOption {
          description = "Network for unlocking wireguard devices on boot";
          type = with types; (submodule wireguardPeer);
        };
      };
    };
  generateLastIPDigit = prefix: digit: prefix + digit;

  generateWithSuffix =
    prefix: digit: suffix:
    (generateLastIPDigit prefix digit) + "/" + suffix;

  generateWireguardPeer =
    prefix: lastIPDigit: publicKey:
    let
      peer = ({
        IP = (generateWithSuffix prefix lastIPDigit "32");
        publicKey = publicKey;
      });
    in
    peer;

  generateWireguardHost =
    lastIPDigit: mainPublicKey: unlockPublicKey:
    let
      host = ({
        mainIP = (generateLastIPDigit mainPrefix lastIPDigit);
        main = (generateWireguardPeer mainPrefix lastIPDigit mainPublicKey);
        unlock = (generateWireguardPeer unlockPrefix lastIPDigit unlockPublicKey);
      });
    in
    host;
in
{
  options = {
    networking.ownWireguard = {
      enabled = mkEnableOption "Insert own standard wireguard config";
      currentHost = mkOption {
        description = "Current host to be configured";
        type = with types; submodule wireguardHost;
      };
      # To be referenced in other files or services
      # TODO: Rewrite with attrset(I think one can modularize)
      hosts = mkOption {
        description = "Listing of our wireguard hosts for easy cross-reference";
        type = with types; attrsOf (submodule wireguardHost);
        # TODO: Check if it still crashes if I move this back into the config block
        default = {
          wireguardController = (
            generateWireguardHost "1" "d6yoEQMbMy4M4h45sj28RrgKxYZXRxDHAJ5ASRKZMmQ="
              "81mzxX6r5pTzNqeofAA3L/xYmzrjOiBKQ8tuvBAWOR8="
          );
          fractor = (
            generateWireguardHost "2" "NVntZ0W1QVee6AwXHgp8oxBqxBDbZPeZiDQ4Af2RY3k="
              "N+EOs047k67li395wKrt94mDMSK64SG6xfCXKgrzmAk="
          );
          neurodrive = (
            generateWireguardHost "3" "kEIYSz20OKCGyWcnXlRBSkWBt7DkjKhmb1Xu+0Kc3XY="
              "3gMbw0t8dlUGUnRmmNJlNM75tKsygjpWYD/1fQaekXg="
          );
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enabled {
      sops.secrets."wireguard/wg0_private" = {
        format = "binary";
        sopsFile = ../../secrets/${config.networking.hostName}/wireguard/wg0.priv;
      };
      sops.secrets."wireguard/wg1_private" = {
        format = "binary";
        sopsFile = ../../secrets/${config.networking.hostName}/wireguard/wg1.priv;
      };

      networking.wireguard.interfaces = {
        wg0 = {
          ips = [ cfg.currentHost.main.IP ];
          listenPort = 51820;
          privateKeyFile = config.sops.secrets."wireguard/wg0_private".path;
          peers = [
            {
              publicKey = cfg.hosts.wireguardController.main.publicKey;
              allowedIPs = [
                (generateWithSuffix mainPrefix "0" "24")
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
              publicKey = cfg.hosts.wireguardController.unlock.publicKey;
              allowedIPs = [
                (generateWithSuffix unlockPrefix "0" "24")
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
