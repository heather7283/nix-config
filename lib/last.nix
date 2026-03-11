{ lib }:

with builtins; let
  last = arr: elemAt arr ((length arr) - 1);
in {
  inherit last;
}

