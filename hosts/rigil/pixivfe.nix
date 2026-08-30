{ config, pkgs, lib, ... }:

{
  virtualisation.quadlet.containers.pixivfe = {
    containerConfig = {
      Image = "registry.gitlab.com/pixivfe/pixivfe:latest";
      AutoUpdate = "registry";

      Network = "host"; # for xray warp socks

      EnvironmentFile = config.sops.secrets."pixivfe/env".path;
      Environment = rec {
        PIXIVFE_PORT = 8282;
        PIXIVFE_HOST = "0.0.0.0";

        HTTP_PROXY = "socks5://127.0.0.1:10808";
        HTTPS_PROXY = HTTP_PROXY;
      };
    };
    unitConfig = rec {
      Wants = [ "network-online.target" ];
      After = Wants;
    };
  };
}

