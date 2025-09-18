{
  description = "overlay for hosting expressvpn packages";

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];

    extra-substituters = [
      "https://cache.nixos.org?priority=40"
      "https://cache.ngi0.nixos.org?priority=41"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
    ];
  };

  inputs = {
    # No thunks here; static values only

    # Channels
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs_25_05.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Ecosystems
    nixpkgs_lib.url = "github:nix-community/nixpkgs.lib?dir=lib";

    # Others
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs_lib";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs_unstable";
    };
  };

  outputs =
    {
      flake-parts,
      nixpkgs_lib,
      # Others
      self,
      # Ignore everything else
      ...
    }@inputs:
    let
      inherit (nixpkgs_lib) lib;

      buildSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      targetSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      createBuildTargetSystemMatrix =
        f:
        lib.genAttrs buildSystems (
          buildSystem: lib.genAttrs targetSystems (targetSystem: f buildSystem targetSystem)
        );

      getChannelFor =
        buildSystem: targetSystem:
        (import ./. {
          crossSystem = {
            system = targetSystem;
          };

          system = buildSystem;
        });

      channelsMatrix = createBuildTargetSystemMatrix getChannelFor;
      packagesMatrix = (
        createBuildTargetSystemMatrix (
          buildSystem: targetSystem:
          let
            channel = channelsMatrix.${buildSystem}.${targetSystem};

            inherit (channel) expressvpn;
          in
          expressvpn.pkgs
          // {
            inherit (expressvpn) lib;
          }
        )
      );
    in
    (flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      {
        systems = buildSystems;

        perSystem =
          {
            inputs',
            pkgs,
            self',
            system,
            ...
          }:
          let
            inherit (channelsMatrix."${system}"."${system}") nixpkgs;
          in
          with nixpkgs;
          {
            devShells = rec {
              default = full;

              common = mkShell {
                packages = [
                  curl
                  dig
                  findutils
                  jq
                  which
                ]
                ++ lib.optionals (stdenv.hostPlatform.isLinux) [
                  iputils
                ];
              };

              ci = mkShell {
                packages = lib.lists.unique (
                  common.nativeBuildInputs
                  ++ [
                    dnsmasq
                    nix-serve-ng
                  ]
                );
              };

              full = mkShell {
                packages = lib.lists.unique (
                  common.nativeBuildInputs
                  ++ [
                    nix-tree
                  ]
                  ++ (with packagesMatrix."${system}"."${system}"; [
                    lightway__edge
                  ])
                );
              };
            };

            formatter = nixfmt-rfc-style;
          };
      }
    )
    // {
      lib = {
        inherit
          buildSystems
          targetSystems
          createBuildTargetSystemMatrix
          getChannelFor
          channelsMatrix
          packagesMatrix
          ;
      };

      # just merge in the packages when buildSystem == targetSystem
      # so that the .#default target works as expected
      channels = lib.genAttrs buildSystems (
        system: channelsMatrix."${system}" // channelsMatrix."${system}"."${system}"
      );

      packages = lib.genAttrs buildSystems (
        system: packagesMatrix."${system}" // packagesMatrix."${system}"."${system}"
      );
    };
}
