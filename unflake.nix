{
  system ? builtins.currentSystem,
  # Ignore everything else
  ...
}:
let
  flake =
    (import ./flake-compat.nix {
      src = ./.;

      inherit system;
    }).outputs;
in
flake
