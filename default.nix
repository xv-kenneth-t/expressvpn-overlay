{
  crossSystem ? null,
  system ? builtins.currentSystem,
  # Ignore everything else
  ...
}:
let
  channels = import ./channels.nix {
    inherit system;

    crossSystem =
      if (crossSystem != null && (crossSystem.system or null) == system) then null else crossSystem;

    # default channel config
    config = {
      allowUnfree = true;
    };
  };

  flake = import ./unflake.nix { inherit system; };

  inherit (flake.inputs.nixpkgs_lib.outputs) lib;

  inherit (lib.lists) foldl;

  # extends to apply by default
  applyExtendsTo =
    nixpkgs:
    let
      extendsWith = [ ];
    in
    (foldl (base: extendWith: base.extend (final: prev: extendWith final prev)) nixpkgs) extendsWith;

  # channels with default extends applied
  nixpkgs = applyExtendsTo channels.nixpkgs;
  nixpkgs_unstable = applyExtendsTo channels.nixpkgs_unstable;
  nixpkgs_25_05 = applyExtendsTo channels.nixpkgs_25_05;
in
{
  # Channels
  inherit
    nixpkgs
    nixpkgs_unstable
    nixpkgs_25_05
    ;

  # Package sets
  inherit (nixpkgs)
    expressvpn
    ;
}
