{ lib }:

with builtins; let
  split = sep: str: filter (e: typeOf e == "string") (builtins.split sep str);
  lstrip = str: elemAt (split "^[[:space:]]*" str) 1;
  lstripLines = str: concatStringsSep "\n" (map (s: lstrip s) (split "\n" str)) ;
in {
  inherit split lstrip lstripLines;
}

