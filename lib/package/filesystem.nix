{
  # Libraries
  callPackage,
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
let
  inherit (lib.filesystem)
    pathIsDirectory
    pathIsRegularFile
    ;

  inherit (expressvpn.lib.strings)
    hasPrefix
    trimPrefix
    trimSuffix
    ;

  normalizeNameFromPath =
    {
      path,
      prefix ? "",
    }:
    let
      # Remove the prefix if it exists
      strippedPath = if hasPrefix prefix path then trimPrefix prefix path else path;

      # Replace all slashes with double underscores
      # and all dots with single underscore
      finalName = builtins.replaceStrings [ "." ] [ "_" ] (
        builtins.replaceStrings [ "/" ] [ "__" ] strippedPath
      );
    in
    # Ensure no leading or trailing underscores if the prefix removal
    # or slash replacement results in them due to edge cases (e.g., prefix is also a slash)
    trimPrefix "_" (trimSuffix "_" finalName);

  pathIsEmptyOrNull = path: path == "" || path == null;
  pathIsNotEmptyOrThrow = path: if !pathIsEmptyOrNull path then true else throw "path is empty";
in
{
  inherit
    pathIsDirectory
    pathIsRegularFile
    normalizeNameFromPath
    pathIsEmptyOrNull
    pathIsNotEmptyOrThrow
    ;
}
