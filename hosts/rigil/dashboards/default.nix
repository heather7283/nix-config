{ lib, ... }:

{
  environment.etc = with builtins; readDir ./.
    |> attrNames
    |> filter (f: null != match "^.*\.json$" f)
    |> map (f: { name = "grafana-dashboards/${f}"; value = { source = ./${f}; }; })
    |> listToAttrs
  ;
}

