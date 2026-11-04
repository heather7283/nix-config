{ config, pkgs, lib, ... }:

let
  name = "sillytavern";
  uid = 990;
in {
  users = {
    users."${name}" = {
      inherit uid;
      group = name;
    };
    groups."${name}" = {
      gid = uid;
    };
  };

  systemd.tmpfiles.settings."${name}" = let
    tmpl = dir: {
      name = "/var/lib/${name}/${dir}";
      value.d = {
        mode = "0700";
        user = name;
        group = name;
      };
    };
  in builtins.listToAttrs <| builtins.map tmpl [
    "data" "plugins" "extensions"
  ];

  sops.templates."${name}-config.yaml" = {
    content = ''
      listen: true
      listenAddress:
        ipv4: 0.0.0.0
        ipv6: '[::]'
      port: 8123
      whitelistMode: false

      heartbeatInterval: 0

      # this stupid software refuses to run when configuration is "insecure"
      basicAuthMode: true
      basicAuthUser:
        username: heather
        password: ${config.sops.placeholder."${name}/password"}
    '';
    group = config.users.users."${name}".group;
    mode = "0440";
    restartUnits = [ "sillytavern.service" ];
  };

  # https://github.com/SillyTavern/SillyTavern/blob/06bde939fb1e9c4c8d8641d810f0a916b5bce127/docker/docker-compose.yml
  virtualisation.quadlet.containers."${name}" = {
    containerConfig = let
      sillytavernConfig = config.sops.templates."${name}-config.yaml".path;
    in {
      HostName = name;
      Image = "ghcr.io/sillytavern/sillytavern:latest";
      AutoUpdate = "registry";

      User = toString config.users.users."${name}".uid;
      Group = toString config.users.groups."${name}".gid;
      Volume = [
        "${sillytavernConfig}:/home/node/app/config/config.yaml"
        "/var/lib/sillytavern/data:/home/node/app/data"
        "/var/lib/sillytavern/plugins:/home/node/plugins"
        "/var/lib/sillytavern/extensions:/home/node/app/public/scripts/extensions/third-party"
      ];

      # Noisy af
      #HealthCmd = "node src/healthcheck.js";
      #HealthInterval = "30s";
      #HealthTimeout = "10s";
      #HealthStartPeriod = "20s";
      #HealthRetries = 3;

      Network = "host"; # for omniroute proxy access
      #PublishPort = "8123:8123";

      Environment = rec {
        NODE_ENV = "production";
      };
    };
    unitConfig = rec {
      Wants = [ "network-online.target" ];
      After = Wants;
    };
  };
}

