{
  system ? builtins.currentSystem,
  # Ignore everything else
  ...
}:
final: prev:
let
  composeManyExtensions = prev.lib.composeManyExtensions;

  overlays = [
    (import ./expressvpn.nix)
    (import ./rust.nix { inherit system; })
  ];
in
composeManyExtensions overlays final prev
