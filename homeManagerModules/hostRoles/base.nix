{
  config,
  lib,
  inputs,
  osConfig,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.myOptions.hostRoles.base;
in
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
  ];

  options.myOptions.hostRoles.base = {
    enable = lib.mkOption {
      description = "Enable home manager";
      type = lib.types.bool;
      default = osConfig.myOptions.hostRoles.base.enable;
    };
    # TODO: Implement
    theming = lib.mkOption {
      description = "Enable theming";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

        xdg.userDirs.createDirectories = true;
        programs.home-manager.enable = true;

        programs.nix-index-database.comma.enable = osConfig.programs.nix-index-database.comma.enable;
        stylix = {
          inherit (osConfig.stylix) image polarity;

          enable = true;
          base16Scheme = osConfig.stylix.generated.palette;
          # Broken targets
          targets.nixos-icons.enable = false;
        };

        news.display = "silent";
      }
      (lib.mkIf osConfig.security.ownAdditional.yubikey {
        # Thanks to joinemm for the guide!(https://joinemm.dev/blog/yubikey-nixos-guide)
        programs.gpg = {
          enable = true;
          package = pkgs.gnupg-with-pin-caching;
          # https://support.yubico.com/hc/en-us/articles/4819584884124-Resolving-GPG-s-CCID-conflicts
          # https://wiki.archlinux.org/title/YubiKey#gpg:_no_such_device
          scdaemonSettings = {
            disable-ccid = true;
            pcsc-shared = true;
          };
          settings = {
            # Copied from: https://github.com/drduh/YubiKey-Guide/blob/master/config/gpg.conf
            personal-cipher-preferences = "AES256 AES192 AES";
            personal-digest-preferences = "SHA512 SHA384 SHA256";
            personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
            # Default preferences for new keys
            default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
            # SHA512 as digest to sign keys
            cert-digest-algo = "SHA512";
            # SHA512 as digest for symmetric ops
            s2k-digest-algo = "SHA512";
            # AES256 as cipher for symmetric ops
            s2k-cipher-algo = "AES256";
            # UTF-8 support for compatibility
            charset = "utf-8";
            # No comments in messages
            no-comments = true;
            # No version in output
            no-emit-version = true;
            # Disable banner
            no-greeting = true;
            # Long key id format
            keyid-format = "0xlong";
            # Display UID validity and list expired subkeys
            list-options = "show-uid-validity show-unusable-subkeys";
            verify-options = "show-uid-validity";
            # Display all keys and their fingerprints
            with-fingerprint = true;
            # Cross-certify subkeys are present and valid
            require-cross-certification = true;
            # Enforce memory locking to avoid accidentally swapping GPG memory to disk
            require-secmem = true;
            # Enable caching of passphrase for symmetrical ops
            no-symkey-cache = false;
            # Output ASCII instead of binary
            armor = true;
            # Enable smartcard
            use-agent = true;
            # Disable recipient key ID in messages (warning: breaks Mailvelope)
            throw-keyids = true;
            # TODO: What keyservers are enable by default?
            # keyserver = "hkps://keys.openpgp.org hkps://keyserver.ubuntu.com:443";
            # Enable key retrieval using WKD and DANE
            auto-key-locate = "wkd,dane,local";
            auto-key-retrieve = true;
          };
          publicKeys = [
            {
              source = "${secrets}/public/gpg/yubikey_personal.asc";
              trust = "ultimate";
            }
          ];
        };

        services.gpg-agent = {
          enable = true;

          # Default
          defaultCacheTtl = 600;
          maxCacheTtl = 7200;
          defaultCacheTtlSsh = 600;
          maxCacheTtlSsh = 7200;

          enableSshSupport = true;
          enableExtraSocket = true;
          pinentry.package = lib.mkDefault pkgs.pinentry-gnome3;
          verbose = true;
          extraConfig = ''
            allow-loopback-pinentry
          '';
        };

        systemd.user.services.gpg-agent.Service.ExecStart =
          lib.mkForce "${config.programs.gpg.package}/bin/gpg-agent --supervised --verbose --verbose --verbose";
      })
    ]
  );
}
