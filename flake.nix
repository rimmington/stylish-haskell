{
  inputs.haskell-nix.url = "github:input-output-hk/haskell.nix";
  inputs.nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.haskell-nix-utils.url = "gitlab:rimmington/haskell-nix-utils";
  outputs = { self, nixpkgs, flake-utils, haskell-nix, haskell-nix-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
    let
      overlays = [
        haskell-nix.overlay
        haskell-nix-utils.overlays.default
      ];
      pkgs = import nixpkgs { inherit system overlays; inherit (haskell-nix) config; };
      utils = pkgs.haskell-nix-utils;
      project = utils.stackageProject' {
        resolver = "lts-22.4";
        name = "stylish-haskell";
        src = utils.cleanGitHaskellSource { name = "stylish-haskell-src"; src = self; };
        cabalFile = ./stylish-haskell.cabal;
        # fromHackage = utils.hackage-sets.hls_2_5_0_0;
        fromHackage = {
          ghc-lib-parser = "9.8.1.20231009";
          ghc-lib-parser-ex = "9.8.0.0";
        };
        modules = [
          {
            # https://github.com/haskell/haskell-language-server/issues/3185#issuecomment-1250264515
            packages.hlint.flags.ghc-lib = true;
            # https://github.com/haskell/haskell-language-server/blob/5d5f7e42d4edf3f203f5831a25d8db28d2871965/cabal.project#L67
            packages.ghc-lib-parser-ex.flags.auto = false;
            packages.stylish-haskell.flags.ghc-lib = true;

            # Disable unused formatters that take a while to build
            packages.haskell-language-server.flags.fourmolu = false;
            packages.haskell-language-server.flags.ormolu = false;
          }
        ];
        shell = {
          withHoogle = false;
          exactDeps = true;
          withHaddock = true;
          nativeBuildInputs = [
            pkgs.cabal-install
            # project.hsPkgs.haskell-language-server.components.exes.haskell-language-server
            project.roots
          ];
        };
      };
    in project.flake');

  nixConfig = {
    allow-import-from-derivation = "true";
  };
}
