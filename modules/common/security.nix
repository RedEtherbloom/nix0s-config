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
      # Yubikey
      services.udev.packages = with pkgs; [
        yubikey-personalization
      ];
      services.pcscd.enable = true;

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      security.pam.services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
    })
  ];
}
