{ lib }:

let
  flattenAttrs = separator: attrset: let
    flatten = prefix: value: if lib.isAttrs value then
      value
        |> lib.mapAttrsToList (name: value: flatten (prefix ++ [ name ]) value)
        |> lib.foldl' lib.mergeAttrs {}
    else
      { "${lib.concatStringsSep separator prefix}" = value; }
    ;
  in
    flatten [] attrset
  ;
in {
  inherit flattenAttrs;
}

