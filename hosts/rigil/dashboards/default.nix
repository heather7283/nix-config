{ pkgs, lib, ... }:

let
  remote = {
    "grafana-dashboards/node-exporter-full.json" = {
      source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/42/download";
        hash = "sha256-pNgn6xgZBEu6LW0lc0cXX2gRkQ8lg/rer34SPE3yEl4=";
      };
    };
    "grafana-dashboards/tor-relay.json" = {
      source = let
        rev = "903a644c7bcae83287e399f4d04c5352df47f9f9";
      in pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/BushyToaster88/Tor-Relay-Grafana-Dashboard/${rev}/Tor%20Relay%20Monitoring.json";
        hash = "sha256-uRkEP1+C/p5wCi44Ob/L8+FC7YPt0ZZ7ssYY3txg0HA=";
      };
    };
  };
  local = with builtins; readDir ./.
    |> attrNames
    |> filter (f: null != match "^.*\.json$" f)
    |> map (f: { name = "grafana-dashboards/${f}"; value = { source = ./${f}; }; })
    |> listToAttrs
  ;
in {
  environment.etc = remote // local;
}

