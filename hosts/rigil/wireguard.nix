{ config, lib, pkgs, ... }:

{
  networking.wireguard = {
    useNetworkd = true;
    interfaces.wg0 = {
      ips = [ "10.20.30.1/32" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wireguard/private-key".path;
      peers = [
        {
          # fa506ih
          publicKey = "diTNVpvmxrbdb/cGAX+442naDBBKUOVrqOuT6juWPGQ=";
          allowedIPs = [ "10.20.30.2/32" ];
        }
        {
          # pluto; proxima reachable through pluto
          publicKey = "pLUtoUowRkkp4a00eimV7oBhUzq4JgHk9OIi5oP7wTA=";
          allowedIPs = [ "10.20.30.50/32" "10.20.30.41/32" ];
        }
      ];
    };
  };
}

