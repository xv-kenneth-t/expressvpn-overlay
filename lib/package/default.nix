{
  # Libraries
  callPackage,
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
let
  inherit (lib)
    warn
    ;

  filesystem = callPackage ./filesystem.nix { };
  loader = callPackage ./loader.nix { };

  inherit (filesystem)
    pathIsPackage
    ;

  callPackageWith =
    caller: path: args:
    if pathIsPackage path then
      (caller path args)
    else
      warn "'${builtins.baseNameOf path}' is not a valid package" { };

  callPackage' = callPackageWith callPackage;
in
filesystem
// {
  inherit
    filesystem
    loader
    callPackageWith
    ;

  callPackage = callPackage';
}
