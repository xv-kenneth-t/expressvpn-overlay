{
  # Libraries from nixpkgs
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
{
  major ? 0,
  minor ? 0,
  patch ? 0,
  suffix ? "",
  # Ignore everything else
  ...
}:
let
  thisVersionWithMajor = "${toString major}";
  thisVersionWithMajorMinor =
    thisVersionWithMajor + (if minor != null then ".${toString minor}" else "");
  thisVersionWithMajorMinorPatch =
    thisVersionWithMajorMinor + (if patch != null then ".${toString patch}" else "");

  thisVersionFull = "${thisVersionWithMajorMinorPatch}${suffix}";
in
rec {
  inherit
    major
    minor
    patch
    suffix
    ;

  strWithoutSuffix = thisVersionWithMajorMinorPatch;
  str = thisVersionFull;

  isSameAs = version: builtins.compareVersions thisVersionFull version == 0;
  isOlderThan = version: builtins.compareVersions thisVersionFull version == -1;
  isAtLeast = version: !(isOlderThan version);
}
