{
  # Defaults
  system ? builtins.currentSystem,
  sources ? import ../nix/sources.nix,
  # Package sets
  nixpkgs ? (import ../. { }).nixpkgs,
  # Ignore everything else
  ...
}:
let
  callPackage = nixpkgs.lib.callPackageWith nixpkgs;

  lib = {
    package = callPackage ./package { };

    attrsets = callPackage ./attrsets.nix { };
    concat = callPackage ./concat.nix { };
    filesystem = callPackage ./filesystem.nix { };
    semver = callPackage ./semver.nix { };
    strings = callPackage ./strings.nix { };
  };
in
lib
