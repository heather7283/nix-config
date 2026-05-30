{ pkgs, lib, ... }:

let
  remote = {
    "grafana-dashboards/node-exporter-full.json" = {
      source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/42/download";
        hash = "sha256-pNgn6xgZBEu6LW0lc0cXX2gRkQ8lg/rer34SPE3yEl4=";
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

