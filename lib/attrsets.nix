{
  # Libraries from nixpkgs
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
{
  attrsOrNullIfEmpty = attrs: if builtins.length (builtins.attrNames attrs) == 0 then null else attrs;

  removeByPath =
    pathList: set:
    lib.updateManyAttrsByPath [
      {
        path = lib.init pathList;
        update = old: lib.filterAttrs (n: v: n != (lib.last pathList)) old;
      }
    ] set;
}
