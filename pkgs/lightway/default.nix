{
  # Libraries
  callPackage,
  lib,
  pkgs,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}@inputs:
let
  makeScope = lib.makeScope;
  newScope = pkgs.newScope;

  passthruFn = callPackage ./passthru.nix { };
in
(makeScope newScope (
  self:
  (expressvpn.lib.package.loader {
    path = ./.;

    overrides = {
      all = {
        inherit passthruFn;
      };
    };
  })
  // {
    latest = self."edge" or { };
  }
)).packages
  (callPackage ./. inputs)
