{ config, ... }:

{
  sops.templates."bitcoind-main.conf" = {
    content = ''
      server=1
      disablewallet=1
      rpcbind=127.0.0.1
      rpcbind=10.200.200.1
      rpcallowip=127.0.0.1
      rpcallowip=10.200.200.2
      rpcauth=${config.sops.placeholder."bitcoind/rpcauth"}

      # I really want to contribute to the network but my hardware is dogshit
      listen=0
      listenonion=0
      blocksonly=1
      prune=1024

      # systemd journal already does this
      logtimestamps=0
    '';
    restartUnits = [ "bitcoind-main.service" ];
  };
  services.bitcoind.main = {
    enable = false;
    extraConfig = ''
      includeconf=/run/credentials/bitcoind-main.service/bitcoind.conf
    '';
  };

  systemd.services.bitcoind-main = {
    enable = false;
    bindsTo = [ "wireguard-wg0.target" ];
    after = [ "wireguard-wg0.target" ];

    serviceConfig = {
      # bitcoind logs are extremely noisy (at least when syncing)
      LogNamespace = "bitcoind";
      # stop eating all my CPU mf
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      # probably placebo but eh
      Environment = [ "MALLOC_ARENA_MAX=1" ];
      # surely
      LoadCredential = [ "bitcoind.conf:${config.sops.templates."bitcoind-main.conf".path}" ];
    };
  };
}

