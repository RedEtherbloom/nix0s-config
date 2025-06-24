{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.ssdp;
in {
  options.myOptions.roles.ssdp = {
    enable = lib.mkOption {
      description = "Keep ports used for SSDP in the firewall open for a certain time after the request so that the response can be properly received.";
      type = lib.types.bool;
      default = false;
    };
    ssdpPort = lib.mkOption {
      description = "Port to use for SSDP.";
      type = lib.types.port;
      default = 1900;
    };
    timeout = lib.mkOption {
      description = "Seconds to keep the port open after the request. 0 is equivalent to permanent.";
      # Max allowed timeeout by ipset
      type = lib.types.ints.u32;
      default = 3;
    };
    ipv4 = {
      enable = lib.mkOption {
        description = "Enable SSDP for IPv4.";
        type = lib.types.bool;
        default = true;
      };
      # TODO: Implement for upstreaming
      srcIp = lib.mkOption {
        description = "IPv4 addresses to allow receiving SSDP from. Defaults to everyone.";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      dstIp = lib.mkOption {
        description = "Multicast IPv4 addresses to allow SSDP packages to be sent on.";
        type = lib.types.listOf lib.types.str;
        default = [
          "239.255.255.250"
        ];
      };
    };
    ipv6 = {
      enable = lib.mkOption {
        description = "Enable SSDP for IPv6.";
        type = lib.types.bool;
        default = true;
      };
      # TODO: Implement for upstreaming
      srcIp = lib.mkOption {
        description = "IPv6 addresses to allow receiving SSDP from. Defaults to everyone.";
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      dstIp = lib.mkOption {
        description = "Multicast IPv6 addresses to allow SSDP packages to be sent on.";
        type = lib.types.listOf lib.types.str;
        default = [
          # Link local
          "ff02::c"
          # Site local
          "ff05::c"
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Based on https://github.com/NixOS/nixpkgs/issues/161328#issuecomment-2887592635. Thank you very much pshirshov!
    networking.firewall = {
      # Is this neccessary?
      #allowedUDPPorts = [cfg.ssdpPort];

      extraPackages = [
        pkgs.ipset
        pkgs.iptables
      ];
      # TODO: Write teardown script, firewall rules are not getting correctly flushed
      extraCommands = lib.strings.concatLines [
        # TODO: Read how to do with idempotent nix. Also, what does this do?
        # TODO: nftables is the successor to iptables and seems to have an integrated set functionality => Read.
        # TODO: Read https://wiki.archlinux.org/title/Iptables#Allowing_multicast_traffic for general advice
        ''
          set -xe
          function apply_if_not_yet() {
            cmd=$1
            # Removes the first two arguments
            shift
            shift
            $cmd -C $* >/dev/null 2>&1 || $cmd -A $*
          }
        ''
        (lib.strings.optionalString cfg.ipv4.enable ''
          ipset list upnp >/dev/null 2>&1 || ipset create upnp hash:ip,port timeout ${builtins.toString cfg.timeout}
          apply_if_not_yet iptables -A OUTPUT -p udp -m udp --dport ${builtins.toString cfg.ssdpPort} -j SET --add-set upnp src,src --exist
          apply_if_not_yet iptables -A INPUT -p udp -m set --match-set upnp dst,dst -j ACCEPT
        '')
        (lib.strings.optionalString cfg.ipv6.enable ''
          ipset list upnp6 >/dev/null 2>&1 || ipset create upnp6 hash:ip,port family inet6 timeout ${builtins.toString cfg.timeout}
          apply_if_not_yet ip6tables -A OUTPUT -p udp -m udp --dport ${builtins.toString cfg.ssdpPort} -j SET --add-set upnp6 src,src --exist
          apply_if_not_yet ip6tables -A INPUT -p udp -m set --match-set upnp6 dst,dst -j ACCEPT
        '')
      ];
    };
  };
}
