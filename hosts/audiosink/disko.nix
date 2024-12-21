{config, ...}: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
          type = "table";
          format = "msdos";
          partitions = [
            {
              name = "firmware";
              # Replicating the Raspberry pi installer
              #type = "0B";
              fs-type = "fat32";
              part-type = "primary";
              start = "8M";
              end = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
                mountOptions = ["umask=0077"];
              };
            }
            {
              name = "boot";
	      # Do I need this?
              fs-type = "ext4";
	      # Do I need this?
              part-type = "primary";
	      # 2Gb size
              start = "512M";
              end = "2560M";
              bootable = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
              };
            }
            {
              name = "luks-crypted";
              part-type = "primary";
              start = "2560M";
              end = "100%FREE";
              bootable = true;
              content = {
                name = "luks-crypted";
                type = "luks";
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
            }
          ];
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
