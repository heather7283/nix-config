{ lib, pkgs, config, ... }:

{
  options.ext.zram = {
    enable = lib.mkEnableOption "Enable zram";
  };

  config = let
    cfg = config.ext.zram;
  in lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      priority = 200;
    };

    boot.kernel.sysctl = lib.ext.flattenAttrs "." {
      # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
      vm = {
        swappiness = 180;
        watermark_boost_factor = 0;
        watermark_scale_factor = 125;
        page-cluster = 0;
      };
    };

    boot.zswap.enable = false;
  };
}

