{
  # Libraries from nixpkgs
  lib,
  # Package sets
  expressvpn,
  # Ignore everything else
  ...
}:
rec {
  inherit (builtins)
    stringLength
    substring
    ;

  inherit (lib.strings)
    hasPrefix
    hasSuffix
    ;

  trimPrefix =
    needle: haystack:
    let
      # Use a fixed point to repeatedly trim the prefix
      trim =
        s:
        if hasPrefix needle s then
          trim (substring (stringLength needle) (stringLength s - stringLength needle) s)
        else
          s;
    in
    trim haystack;

  trimSuffix =
    needle: haystack:
    let
      # Use a fixed point to repeatedly trim the suffix
      trim =
        s: if hasSuffix needle s then trim (substring 0 (stringLength s - stringLength needle) s) else s;
    in
    trim haystack;
}
