{
  # Libraries
  fetchFromGitHub,
  lib,
  testers,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
{
  # Inputs
  version,
  src,
  # Self reference
  self,
}:
let
  semver = expressvpn.lib.semver version;
  version' = semver.str;
  versionSameAs = v: semver.isSameAs v;
  versionOlderThan = v: semver.isOlderThan v;
  versionAtLeast = v: semver.isAtLeast v;

  src' =
    src.override or (fetchFromGitHub (
      {
        owner = "expressvpn";
        repo = "lightway";
        rev = "${version'}";
        hash = src.hash;
      }
      // src
    ));
in
{
  version = version';
  src = src';

  inherit
    self
    versionSameAs
    versionOlderThan
    versionAtLeast
    ;

  tests = {
    pkg-config = testers.testMetaPkgConfig self;
  };
}
