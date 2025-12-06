{ ... }:

{
  disko.devices = {
    disk.disk1 = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            type = "EF02";
            size = "1M";
          };
          esp = {
            name = "esp";
            type = "EF00";
            size = "500M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              mountpoint = "/";
              mountOptions = [ "compress=zstd" "noatime" ];
              subvolumes = {
                "/swap" = {
                  mountpoint = "/swap";
                  swap.swapfile.size = "1G";
                };
              };
            };
          };
        };
      };
    };
  };
}
