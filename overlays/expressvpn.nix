final: prev:
let
  makeOverridable = prev.lib.makeOverridable;

  newScope = extra: prev.lib.callPackageWith (prev // defaults // extra);
  defaults = {
    # Libraries
    callPackageWith = final.lib.callPackageWith;
    # Package sets
    nixpkgs = final;
  };
in
{
  expressvpn =
    (final.lib.makeScope newScope (self: {
      sources = import ../sources.nix;

      channels = import ../channels.nix {
        inherit (final) config system;
      };

      lib = makeOverridable (
        {
          # Defaults
          system ? true,
          sources ? true,
          # Package sets
          nixpkgs ? true,
          # Ignore everything else
          ...
        }@inputs:
        import ../lib inputs
      ) defaults;

      pkgs = makeOverridable (
        {
          # Package sets
          nixpkgs ? true,
          expressvpn ? true,
          # Ignore everything else
          ...
        }@inputs:
        import ../pkgs inputs
      ) defaults;
    })).packages
      { };
}
