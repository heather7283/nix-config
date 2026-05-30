{ lib, ... }:

{
  disko.devices = {
    disk.disk1 = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "bios";
            type = "EF02";
            size = "1M";
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              mountpoint = "/";
              mountOptions = [ "compress=zstd" ];
            };
          };
        };
      };
    };
  };
}

