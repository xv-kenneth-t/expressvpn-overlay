{
  # Libraries from nixpkgs
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
list:
let
  concatFn = lib.lists.foldr (a: b: toString a + toString b) "";
in
concatFn list
