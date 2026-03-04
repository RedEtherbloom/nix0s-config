{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.networking.ownWireguard;

  mainPrefix = "10.69.0.";
  unlockPrefix = "10.68.0.";

  wireguardPeer = _: {
    options = {
      IP = lib.mkOption {
        description = "IPv4 of the wireguard client";
        type = lib.types.str;
      };
      publicKey = lib.mkOption {
        description = "Public key of the wireguard client";
        type = lib.types.str;
      };
    };
  };
  wireguardHost = _: {
    options = {
      # For easier access
      mainIP = lib.mkOption {
        description = "Main IPv4 without suffix";
        type = lib.types.str;
      };
      main = lib.mkOption {
        description = "Main wireguard network";
        type = lib.types.submodule wireguardPeer;
      };
      unlock = lib.mkOption {
        description = "Network for unlocking wireguard devices on boot";
        type = lib.types.submodule wireguardPeer;
      };
    };
  };
  generateLastIPDigit = prefix: digit: prefix + digit;

  generateWithSuffix = prefix: digit: suffix:
    (generateLastIPDigit prefix digit) + "/" + suffix;

  generateWireguardPeer = prefix: lastIPDigit: publicKey: let
    peer = {
      IP = generateWithSuffix prefix lastIPDigit "32";
      inherit publicKey;
    };
  in
    peer;

  generateWireguardHost = lastIPDigit: mainPublicKey: unlockPublicKey: let
    host = {
      mainIP = generateLastIPDigit mainPrefix lastIPDigit;
      main = generateWireguardPeer mainPrefix lastIPDigit mainPublicKey;
      unlock = generateWireguardPeer unlockPrefix lastIPDigit unlockPublicKey;
    };
  in
    host;
in {
  options = {
    networking.ownWireguard = {
      enable = lib.mkEnableOption "Insert own standard wireguard config";
      currentHost = lib.mkOption {
        description = "Current host to be configured";
        type = lib.types.submodule wireguardHost;
        default = config.networking.ownWireguard.hosts."${config.networking.hostName}";
      };
      # To be referenced in other files or services
      # TODO: Rewrite with attrset(I think one can modularize)
      hosts = lib.mkOption {
        description = "Listing of our wireguard hosts for easy cross-reference";
        type = lib.types.attrsOf (lib.types.submodule wireguardHost);
        # TODO: Check if it still crashes if I move this back into the config block
        default = {
          wireguardController =
            generateWireguardHost "1" "d6yoEQMbMy4M4h45sj28RrgKxYZXRxDHAJ5ASRKZMmQ="
            "81mzxX6r5pTzNqeofAA3L/xYmzrjOiBKQ8tuvBAWOR8=";
          fractor =
            generateWireguardHost "2" "NVntZ0W1QVee6AwXHgp8oxBqxBDbZPeZiDQ4Af2RY3k="
            "N+EOs047k67li395wKrt94mDMSK64SG6xfCXKgrzmAk=";
          neurodrive =
            generateWireguardHost "3" "kEIYSz20OKCGyWcnXlRBSkWBt7DkjKhmb1Xu+0Kc3XY="
            "3gMbw0t8dlUGUnRmmNJlNM75tKsygjpWYD/1fQaekXg=";
          audiosink =
            generateWireguardHost "6" "bvDwdiRWJAXr3up4k+34w8ATqcx6t98jTnmSsjBVhFE="
            "HvQA5s03k1w3dwTwjSR3/dasUeUNGD+fTskz///2nj0=";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = [pkgs.wireguard-tools];

      sops.secrets."wireguard/wg0_private" = {
        format = "binary";
        sopsFile = "${secrets}/secrets/${config.networking.hostName}/wireguard/wg0.priv";
      };
      sops.secrets."wireguard/wg1_private" = {
        format = "binary";
        sopsFile = "${secrets}/secrets/${config.networking.hostName}/wireguard/wg1.priv";
      };

      networking = {
        wireguard.interfaces = {
          wg0 = {
            ips = [cfg.currentHost.main.IP];
            listenPort = 51820;
            privateKeyFile = config.sops.secrets."wireguard/wg0_private".path;
            peers = [
              {
                inherit (cfg.hosts.wireguardController.main) publicKey;
                allowedIPs = [
                  (generateWithSuffix mainPrefix "0" "24")
                ];
                endpoint = "51.15.91.213:51820";
                persistentKeepalive = 25;
              }
            ];
          };
          wg1 = {
            ips = [cfg.currentHost.unlock.IP];
            listenPort = 51821;
            privateKeyFile = config.sops.secrets."wireguard/wg1_private".path;
            peers = [
              {
                inherit (cfg.hosts.wireguardController.unlock) publicKey;
                allowedIPs = [
                  (generateWithSuffix unlockPrefix "0" "24")
                ];
                endpoint = "51.15.91.213:51821";
                persistentKeepalive = 25;
              }
            ];
          };
        };

        firewall = {
          allowedUDPPorts =
            lib.attrsets.mapAttrsToList (
              _: value: value.listenPort
            )
            config.networking.wireguard.interfaces;

          # Ports for e.g. comfyui
          interfaces."wg0" = {
            allowedTCPPortRanges = [
              {
                from = 8000;
                to = 8999;
              }
            ];
            allowedUDPPortRanges = [
              {
                from = 8000;
                to = 8999;
              }
            ];
          };
        };
      };
    })
  ];
}
