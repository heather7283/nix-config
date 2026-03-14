{ pkgs, lib, ... }:

let
  remote = {
    "grafana-dashboards/node-exporter-full.json" = {
      source = pkgs.fetchurl {
        url = "https://github.com/rfmoz/grafana-dashboards/raw/76b2125f29757fc4886b8f25c6fa7ce96878fc4c/prometheus/node-exporter-full.json";
        hash = "sha256-Y+zsL4I+K3/j2+YoGU/JFp7cYWOhIvil/KkIF/M22fQ=";
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

