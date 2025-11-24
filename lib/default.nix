{ lib }:

let
  flattenAttrs = separator:
    let
      flatten = prefix: value:
        if lib.isAttrs value then
          lib.foldl' lib.mergeAttrs {} (
            lib.mapAttrsToList
              (name: v: flatten (prefix ++ [ name ]) v)
              value
          )
        else
          let
            key = lib.concatStringsSep separator prefix;
          in
            { "${key}" = value; };
    in
      value: flatten [] value
  ;
in
  flattenAttrs

