{
  description = "FalkorDB development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          cmake      # build system for GraphBLAS, LAGraph, oniguruma, main project
          autoconf   # autoreconf for libcypher-parser, libcurl, libcsv
          automake   # required by autotools
          libtool    # required by autotools
          pkg-config # package discovery
          openssl    # TLS support
          peg        # provides `leg` parser generator, required by libcypher-parser
          rustup     # Rust toolchain manager — FalkorDB-core-rs requires nightly (-Z flags)
          redis      # run the module: redis-server --loadmodule falkordb.so
        ];

        shellHook = ''
          # rustup shims live in ~/.cargo/bin — add to PATH so cargo/rustc resolve correctly
          export PATH="$HOME/.cargo/bin:$PATH"
          # Ensure nightly toolchain is installed; FalkorDB-core-rs uses -Z flags
          rustup toolchain install nightly --no-self-update --quiet 2>/dev/null || true
          rustup default nightly
        '';

        env = {
          # Optimise for the installed CPU — enables all M5 Max instruction
          # extensions (NEON, AMX etc). Critical for GraphBLAS matrix ops.
          # -O3 is already used per-component in build.sh; setting it here
          # ensures any components that inherit CFLAGS also get it.
          CFLAGS   = "-mcpu=native -O3";
          CXXFLAGS = "-mcpu=native -O3";
        };
      };
    };
}
