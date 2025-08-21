{
  system ? builtins.currentSystem,
  # Ignore everything else
  ...
}:
final: prev:
let
  flake = import ../unflake.nix { inherit system; };
  overlay = flake.inputs.rust-overlay.overlays.default;
in
overlay final prev
