{
  # Libraries from nixpkgs
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
let
  inherit (lib.strings)
    concatStringsSep
    splitString
    ;
in
let
  joinPath =
    segments:
    let
      # Handle leading slash for absolute paths
      leadingSlash = if (builtins.head segments) == "" then "/" else "";

      # Remove empty first segment if it was an absolute path marker
      actualSegments = if (builtins.head segments) == "" then lib.tail segments else segments;
    in
    leadingSlash + concatStringsSep "/" actualSegments;

  normalizeStringPath = path: joinPath (resolveSegments (splitPath path));

  readJsonFromFile = file: builtins.fromJSON (builtins.readFile file);

  resolveSegments =
    segments:
    lib.foldl (
      acc: segment:
      if segment == "." then
        acc
      else if segment == ".." then
        if acc == [ ] || lib.last acc == "" then
          acc # Don't go above root or if it's already empty
        else
          lib.take (builtins.length acc - 1) acc
      else
        acc ++ [ segment ]
    ) [ ] segments;

  splitPath =
    path:
    let
      # Split by "/"
      segments = splitString "/" path;

      # Filter out empty segments that result from multiple slashes
      filteredSegments = builtins.filter (s: s != "") segments;
    in
    if builtins.substring 0 1 path == "/" then
      [ "" ] ++ filteredSegments # Handle absolute paths
    else
      filteredSegments;
in
{
  inherit
    joinPath
    normalizeStringPath
    readJsonFromFile
    resolveSegments
    splitPath
    ;
}
