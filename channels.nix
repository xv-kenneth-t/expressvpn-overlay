{
  config ? { },
  crossSystem ? null,
  system ? builtins.currentSystem,
  # Ignore everything else
  ...
}:
let
  flake = import ./unflake.nix { inherit system; };

  defaultNixpkgsChannelArgs = {
    inherit
      config
      crossSystem
      system
      ;

    overlays = [
      (import ./overlays { inherit system; })
    ];
  };
in
rec {
  # Pinned channels
  nixpkgs_unstable = import flake.inputs.nixpkgs_unstable defaultNixpkgsChannelArgs;
  nixpkgs_25_05 = import flake.inputs.nixpkgs_25_05 defaultNixpkgsChannelArgs;

  # Aliased channels
  nixpkgs = nixpkgs_unstable;
}
