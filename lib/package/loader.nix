{
  # Libraries
  callPackage,
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
{
  path,
  # Options
  blacklists ? [ ],
  overrides ? { },
  # Escape hatches
  nameIsKnownDerivationAttr ? null,
}:
let
  inherit (lib)
    warn
    ;

  inherit (lib.attrsets)
    concatMapAttrs
    foldAttrs
    nameValuePair
    ;

  inherit (lib.lists)
    forEach
    ;

  inherit (lib.strings)
    hasPrefix
    removePrefix
    ;

  inherit (expressvpn.lib.package)
    pathIsDirectory
    ;
in
let
  getDirsAtPath =
    path:
    let
      files = builtins.attrNames (builtins.readDir path);
      filepaths = map (file: path + "/${file}") files;

      dirpaths = builtins.filter (filepath: pathIsDirectory filepath) filepaths;
    in
    dirpaths;

  loadDirs =
    dirs:
    builtins.listToAttrs (
      forEach dirs (
        {
          path,
          blacklists ? [ ],
          overrides ? { },
        }:
        let
          normalizedName = builtins.replaceStrings [ "." ] [ "_" ] (builtins.baseNameOf path);
          isBlacklisted = builtins.elem normalizedName blacklists;
          overrides' = (overrides.all or { }) // (overrides."${normalizedName}" or { });

          attrs =
            if !isBlacklisted then
              if builtins.pathExists path then callPackage path overrides' else { }
            else
              warn "${builtins.baseNameOf path} (${normalizedName}) is blacklisted" { };
        in
        nameValuePair normalizedName attrs
      )
    );

  loadedDirs =
    let
      foundDirs = builtins.concatMap (x: [
        {
          path = x;

          inherit blacklists overrides;
        }
      ]) (getDirsAtPath path);
    in
    loadDirs foundDirs;

  nameIsKnownDerivationAttr' =
    name:
    if nameIsKnownDerivationAttr != null then
      nameIsKnownDerivationAttr name
    else
      ((builtins.match "^[[:digit:]]+.*" name) != null)
      || hasPrefix "edge" name
      || hasPrefix "latest" name
      || hasPrefix "nightly" name;

  by-path = concatMapAttrs (
    n1: v1:
    let
      # TODO: isLoadedViaDiscovery forces v1 to evaluate
      # which may cause infinite recursion or performance
      # issues
      isLoadedViaDiscovery = v1 ? "__loaded_via_discovery";
    in
    {
      "${n1}" = concatMapAttrs (
        n2: v2:
        let
          isPrivate = hasPrefix "_" n2;

          n2' =
            if isLoadedViaDiscovery && n2 == "by-path" then
              # if isLoadedViaDiscovery and name is "by-path"
              # do not transform drv names since we want to passthrough them as-is
              n2
            else
            # if drv name is same as the pkg i.e. hello = { hello = drv; };
            # then rename to "latest"
            if n2 == n1 then
              "latest"
            else
              let
                # strip package name prefix
                suffix = removePrefix "${n1}_" n2;

                # check if name starts with a digit
                isStartsWithDigit = (builtins.match "^[[:digit:]]+.*" suffix) != null;
              in
              if isStartsWithDigit then "v${suffix}" else suffix;
        in
        if !isPrivate then
          # this simulates a "fold" behavior if the name is "by-path"
          # and the value contains "__loaded_via_discovery" set
          # specifically by this loader
          if isLoadedViaDiscovery && n2' == "by-path" then
            v2
          else
            {
              "${n2'}" = v2;
            }
        else
          { }
      ) v1;
    }
  ) loadedDirs;

  all =
    let
      loadedDirs' = concatMapAttrs (
        n1: v1:
        let
          v1' =
            # NOTE: nameIsKnownDerivationAttr' evaluate n1 to determine
            # if the value is a derivation or a "package set"
            #
            # we cannot check for __loaded_via_discovery as it will cause
            # the value to be evaluated, potentially running into infinite
            # recursion issues
            if nameIsKnownDerivationAttr' n1 then { "${n1}" = v1; } else v1;
        in
        {
          "${n1}" = concatMapAttrs (
            n2: v2:
            let
              isPrivate = hasPrefix "_" n2;
              isStartsWithBy = hasPrefix "by-" n2;
              isBlacklistedAttrName = builtins.elem n2 [
                "override"
                "overrideDerivation"
              ];

              n2' =
                # NOTE: we do not want to evaluate values whenever possible
                # to maintain lazy evaluation
                #
                # this also means that we assume that dir containing the loader
                # and the dir containing the derivation will never have the same
                # name i.e. 0.1.0 (with loader)/0.1.0 (with derivation)
                #
                # infinite recursion will happen when we attempt to evaluate attrs
                # because we hoisted all attrs to the top level and derivations
                # using buildPythonApplication will resolve for our overlay again
                # which will re-evaluate attrs ...
                #
                # if both parent and child directory have the same name
                # then it will be treated similarly to results in by-sets
                if n1 != n2 then
                  # prepend parent attr name and separated by double
                  # underscores to denote parent-child relationship
                  "${n1}__${n2}"
                else
                  # keep attr name as-is since the name is explicitly defined
                  # and not inferred by derivation discovery
                  #
                  # this is similar to the by-sets attr
                  n2;
            in
            if !isPrivate && !isStartsWithBy && !isBlacklistedAttrName then
              {
                "${n2'}" = v2;
              }
            else
              { }
          ) v1';
        }
      ) loadedDirs;
    in
    foldAttrs (item: acc: acc // item) { } (builtins.attrValues loadedDirs');
in
{
  __loaded_via_discovery = 1;

  inherit by-path;
}
// (concatMapAttrs (n: v: {
  "${n}" = v;
}) all)
