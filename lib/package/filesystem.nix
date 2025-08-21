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
  inherit (lib)
    makeOverridable
    ;

  inherit (lib.filesystem)
    pathIsDirectory
    pathIsRegularFile
    ;

  inherit (expressvpn.lib)
    readJsonFromFile
    ;

  inherit (expressvpn.lib.strings)
    hasPrefix
    trimPrefix
    trimSuffix
    ;

  appendPathWithDefaultNix = path: path + "/default.nix";
  appendPathWithEarthfile = path: path + "/Earthfile";
  appendPathWithProjectJson = path: path + "/project.json";
  appendPathWithRepoutilYaml = path: path + "/repoutil.yaml";

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

  pathContainsDefaultNix = path: pathIsRegularFile (appendPathWithDefaultNix path);
  pathContainsEarthfile = path: pathIsRegularFile (appendPathWithEarthfile path);
  pathContainsProjectJson = path: pathIsRegularFile (appendPathWithProjectJson path);
  pathContainsRepoutilYaml = path: pathIsRegularFile (appendPathWithRepoutilYaml path);

  pathIsPackage =
    {
      ignoreEarthfile ? false,
      ignoreProjectJson ? false,
      ignoreRepoutilYaml ? false,
    }:
    path:
    (
      !(pathIsEmptyOrNull path)
      && pathIsDirectory path
      && pathContainsDefaultNix path
      && (ignoreEarthfile || pathContainsEarthfile path)
      && (ignoreProjectJson || pathContainsProjectJson path)
      && (ignoreRepoutilYaml || pathContainsRepoutilYaml path)
    );

  pathIsPackage' = makeOverridable pathIsPackage { };
  pathIsPackageOrThrow =
    path:
    if (pathIsNotEmptyOrThrow path) && (pathIsPackage' path) then true else throw "path is not package";

  pathIsInactiveProject =
    path:
    let
      projectJsonPath = appendPathWithProjectJson path;
      hasProjectJson = pathIsRegularFile projectJsonPath;
    in
    if hasProjectJson then
      (
        let
          projectJson = readJsonFromFile projectJsonPath;
          isInactiveProject = builtins.elem "inactive" (projectJson.tags or [ ]);
        in
        if isInactiveProject then true else false
      )
    else
      false;
in
{
  inherit
    pathIsDirectory
    pathIsRegularFile
    appendPathWithDefaultNix
    appendPathWithEarthfile
    appendPathWithProjectJson
    appendPathWithRepoutilYaml
    normalizeNameFromPath
    pathIsEmptyOrNull
    pathIsNotEmptyOrThrow
    pathContainsDefaultNix
    pathContainsEarthfile
    pathContainsProjectJson
    pathContainsRepoutilYaml
    pathIsPackageOrThrow
    pathIsInactiveProject
    ;

  # aliases
  pathIsPackage = pathIsPackage';
}
