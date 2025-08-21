{
  # Libraries
  lib,
  stdenv,
  # Dependencies
  autoconf,
  automake,
  libtool,
  makeRustPlatform,
  # Package set
  expressvpn,
  rust-bin,
  # Others
  passthruFn,
  # Ignore everything else
  ...
}:
let
  passthru = passthruFn {
    inherit self;

    version = {
      major = 99;
      minor = 99;
      patch = 99;
    };

    src = {
      rev = "8edf29434447faa64a0b4aaa90e56b44722ed0c2";
      hash = "sha256-ao+yaIoDnVyfzPid76JGw+Mzikq6sZUpqbF3pD6Cl/8=";
    };
  };

  cargoLock = {
    lockFile = passthru.src + /Cargo.lock;
    outputHashes = {
      "wolfssl-3.0.0" = "sha256-h3ORb5FmIeYyTf23+QhVr7vl+UwRkhAhFqbHiJ+ML9k=";
    };
  };

  rustPlatform =
    let
      toolchain = rust-bin.stable."1.88.0".minimal;
    in
    makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };

  self =
    let
      # Aliases
      inherit (lib) optionals;

      # Build variables
      buildFeatures =
        [ ]
        ++ optionals stdenv.hostPlatform.isLinux [
          "io-uring"
        ];

      nativeBuildInputs = [
        autoconf
        automake
        libtool
        rustPlatform.bindgenHook
      ];

      doCheck = true;
      checkType = "debug";
      checkFlags = [
        # These tests need permission to create tun interface
        "--skip=routing_table::tests"
      ];
    in
    rustPlatform.buildRustPackage {
      pname = "lightway";
      inherit (passthru) version src;

      inherit
        buildFeatures
        nativeBuildInputs
        cargoLock
        doCheck
        checkType
        checkFlags
        ;

      meta = {
        pkgConfigModules = [ ];
        platforms = lib.platforms.all;
      };
    };
in
self
