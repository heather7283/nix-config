{ lib, ... }:

let
  trace = x: builtins.trace x x;
in {
  inherit trace;
}

