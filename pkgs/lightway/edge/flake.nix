{
  nixConfig = { };

  inputs = {
    this = {
      url = ../../..;
    };
  };

  outputs =
    {
      # Package sets
      this,
      # Others
      self,
      # Ignore everything else
      ...
    }@inputs:
    let
      inherit (this.lib) buildSystems createBuildTargetSystemMatrix channelsMatrix;
      inherit (this.inputs) flake-parts nixpkgs_lib;

      inherit (nixpkgs_lib.lib) genAttrs;

      packagesMatrix = (
        createBuildTargetSystemMatrix (
          buildSystem: targetSystem:
          let
            thisPkgs = this.packages."${buildSystem}"."${targetSystem}";
            inherit (thisPkgs.lib.filesystem) normalizeStringPath;
            inherit (thisPkgs.lib.package) normalizeNameFromPath;

            thisPkgName = normalizeNameFromPath {
              path = (builtins.toString ./.);
              prefix = normalizeStringPath (builtins.toString (this + "/pkgs"));
            };
          in
          {
            default = thisPkgs."${thisPkgName}";
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
            self',
            system,
            ...
          }:
          let
            inherit (channelsMatrix."${system}"."${system}") nixpkgs;
          in
          with nixpkgs;
          {
            devShells = with this.devShells."${system}"; {
              default = default // self'.packages.default;
            };

            formatter = this.formatter."${system}";
          };
      }
    )
    // {
      # just merge in the packages when buildSystem == targetSystem
      # so that the .#default target works as expected
      packages = genAttrs buildSystems (
        system: packagesMatrix."${system}" // packagesMatrix."${system}"."${system}"
      );
    };
}
