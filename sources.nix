let
  inherit (builtins)
    fetchTarball
    foldl'
    fromJSON
    readFile
    ;

  lock = fromJSON (readFile ./flake.lock);

  fetchTarballFromGitHub =
    name:
    let
      owner = lock.nodes.${name}.locked.owner;
      repo = lock.nodes.${name}.locked.repo;
      rev = lock.nodes.${name}.locked.rev;
      narHash = lock.nodes.${name}.locked.narHash;
    in
    fetchTarball {
      name = "${name}-src";
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      sha256 = narHash;
    };
in
(foldl' (set: name: set // { "${name}" = fetchTarballFromGitHub name; }) { } [
  # Channels
  "nixpkgs_unstable"
  "nixpkgs_23_11"
  "nixpkgs_24_05"
  "nixpkgs_24_11"
  "nixpkgs_25_05"
  # Ecosystems
  "nixpkgs_lib"
])
