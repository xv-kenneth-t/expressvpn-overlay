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
      rev = "e7221655fae3a64e375935a55b77e5f93cee432a";
      hash = "sha256-CGnUrpxbgbcAcyT+4zlLVZmQT9dliN6q3TAUzkc1uQ0=";
    };
  };

  cargoHash = "sha256-RFlac10XFJXT3Giayy31kZ3Nn1Q+YsPt/zCdkSV0Atk=";

  rustPlatform =
    let
      toolchain = rust-bin.stable."1.89.0".minimal;
    in
    makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };

  self =
    let
      # Aliases
      inherit (lib) optionals optionalString;
      inherit (lib.cli) toGNUCommandLine;

      # Build variables
      env = {
        NIX_CFLAGS_COMPILE =
          with stdenv.hostPlatform;
          optionalString (isAarch && isLinux) "-march=${gcc.arch}+crypto";
      };

      nativeBuildInputs = [
        autoconf
        automake
        libtool
        rustPlatform.bindgenHook
      ];

      cargoDepsName = passthru.self.pname;
      cargoBuildFlags = toGNUCommandLine { } {
        package = [
          "lightway-client"
          "lightway-server"
        ];

        features = optionals stdenv.hostPlatform.isLinux [
          "io-uring"
        ];
      };

      doCheck = true;
      checkType = "release";
    in
    rustPlatform.buildRustPackage {
      pname = "lightway";
      inherit (passthru) version src;

      inherit
        cargoHash
        env
        nativeBuildInputs
        cargoDepsName
        cargoBuildFlags
        doCheck
        checkType
        ;

      meta = with lib; {
        platforms = platforms.darwin ++ platforms.linux;
        mainProgram = "lightway-client";
      };
    };
in
self
