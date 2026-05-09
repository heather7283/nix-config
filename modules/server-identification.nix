{ lib, pkgs, config, ... }:

{
  options.services.ext.server-identification = {
    enable = lib.mkEnableOption "Enable server identification endpoint";
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "/skibidi/toilet";
      description = "Endpoint to serve";
    };
    serverToken = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "What will be sent in response body";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 6767;
      description = "Port to listen on";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open specified port in the firewall";
    };
  };

  config = let
    cfg = config.services.ext.server-identification;
  in lib.mkIf cfg.enable {
    systemd.services.server-identification = {
      description = "HTTP endpoint for server identification";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = let
          script = pkgs.writeScript "server-identification.py" ''
            #!${pkgs.python3}/bin/python3

            from http.server import HTTPServer, BaseHTTPRequestHandler
            from sys import argv

            PORT = int(argv[1])
            ENDPOINT = argv[2]
            SERVER_TOKEN = bytes(argv[3].encode("utf-8"))

            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    if self.path == ENDPOINT:
                        self.send_response(200)
                        self.end_headers()
                        self.wfile.write(SERVER_TOKEN)
                    else:
                        self.send_response(404)
                        self.end_headers()

            HTTPServer(("", PORT), Handler).serve_forever()
          '';
        in lib.concatStringsSep " " [
          script (builtins.toString cfg.port) cfg.endpoint cfg.serverToken
        ];

        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        KeyringMode = "private";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateMounts = "yes";
        PrivateTmp = "yes";
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallFilter = "@system-service";
        SystemCallArchitectures = "native";
        DevicePolicy = "closed";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}

