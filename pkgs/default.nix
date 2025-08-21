{
  # Package sets
  expressvpn ? nixpkgs.expressvpn,
  nixpkgs ? (import ../. { }).nixpkgs,
  # Ignore everything else
  ...
}@inputs:
let
  inherit (nixpkgs)
    callPackage
    lib
    newScope
    ;

  inherit (lib)
    makeScope
    ;
in
(
  (makeScope newScope (
    self:
    (expressvpn.lib.package.loader {
      path = ./.;
    })
  )).packages
  (callPackage ./. inputs)
)
