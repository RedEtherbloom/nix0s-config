{config, ...}: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
          type = "mbr";
          partitions = {
            FIRMWARE = {
              size = "500M";
              type = "EF";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
                mountOptions = ["umask=0077"];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                extraOpenArgs = [];
                settings = {
                  # if you want to use the key for interactive login be sure there is no trailing newline
                  # for example use `echo -n "password" > /tmp/secret.key`
                  keyFile = config.sops.secrets.audiosink_crypto_password.path;
                  allowDiscards = true;
                };
                content = {
                  type = "lvm_pv";
                  vg = "pool_raspberry";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool_raspberry = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
          swap = {
            size = "4G";
            content = {
              type = "swap";
              # Probably not needed due to being installed in a LUKS
              # randomEncryption = true;
              resumeDevice = true;
            };
          };
        };
      };
    };
  };
}
