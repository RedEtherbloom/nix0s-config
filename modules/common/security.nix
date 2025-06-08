{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.security.ownAdditional;
in {
  options.security.ownAdditional = {
    enabled = mkOption {
      type = types.bool;
      default = true;
      description = "Own additional security settings";
    };
    normalUserHibernate = mkOption {
      type = types.bool;
      default = true;
      description = "Allow normal users to hibernate as well";
    };
    yubikey = mkOption {
      type = types.bool;
      default = false;
      description = "Yubikey support";
    };
  };

  config = mkMerge [
    (mkIf cfg.enabled {
      sops.secrets."sudoers/optional" = {
        format = "binary";
        sopsFile = "${inputs.our-secrets}/secrets/common/sudoers";
      };
      security.sudo = {
        enable = true;
        extraConfig = ''
          @includedir ${builtins.dirOf config.sops.secrets."sudoers/optional".path}
        '';
      };

      # in µs
      security.pam.services = {
        sudo.failDelay.delay = 500000;
        kde.failDelay.delay = 500000;
        sddm.failDelay.delay = 500000;
      };
    })

    # Allow hibernation for regular users
    (mkIf cfg.normalUserHibernate {
      security.polkit.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (
            subject.isInGroup("users")
              && (
                action.id == "org.freedesktop.login1.hibernate" ||
                action.id == "org.freedesktop.login1.hibernate-multiple-sessions"
              )
            )
          {
            return polkit.Result.YES;
          }
        });
      '';
    })

    (mkIf cfg.yubikey {
      services = {
        udev.packages = [pkgs.yubikey-personalization];
        pcscd.enable = true;
      };

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      security.pam = {
        u2f = {
          enable = true;
          control = "sufficient";
          settings = {
            origin = "pam://yubi";
            authfile = pkgs.writeText "u2f-mappings" (lib.concatStrings [
              "inf"
              ":64w4vEJ2naXlaGrQhMgpfDN+mONUxzgJN5Qn9RZsLZJSwb47o0cM0hFyQEbYzY7VhpDkijCPALp2lmjU/p2GbQ==,6liBTekvJyy5JGc+rxODEcjqE9oiBtEKNqYoxSHnplU7+hWGZT1zNypdfyP0jb7GPNoMVPaKmuNNg3+0lTpr0w==,es256,+presence"
              ":xFSjBKbX2sdnWcapMi45xQXl+d5gruJe79ajs5hs3VghJn+PXBPLlX28pxHTEBMsbMIbGh9SVjZRxv5Hv2GJJQ==,hYUMlJxeYkok8Em8uiwm30Htrv3mc3h8V3FQmySKDQsj8sZwuBFT9rm3yqppJn2Hr8CA3E8tXb9jBlSXVpsNAA==,es256,+presence"
            ]);
            cue = true;
            # TODO: Do I need interactive? I don't think so
            # interactive = false;
          };
        };
        services = {
          login.u2fAuth = true;
          sudo.u2fAuth = true;
        };
      };
    })
  ];
}
