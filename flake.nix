{
  description = "Personal collection of reusable devShell templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # flake-utils: generates per-system outputs (x86_64-linux, aarch64-darwin, etc.)
    # so you don't have to repeat yourself for each system
    flake-utils.url = "github:numtide/flake-utils";

    # rust-overlay: gives you `rust-bin` — the proper way to pin Rust toolchains in Nix.
    # Much better than raw nixpkgs rust because you can pick stable/beta/nightly
    # and add extensions (rust-src, rust-analyzer, clippy…) easily.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs"; # share nixpkgs with the parent flake
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    # eachDefaultSystem iterates over common systems and produces outputs for all of them
    flake-utils.lib.eachDefaultSystem (system:
      let
        # overlays are functions that extend / replace packages in nixpkgs.
        # rust-overlay injects `rust-bin` into pkgs so we can use it below.
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
      in
      {
        devShells = {

          # ──────────────────────────────────────────────
          # 🦀  Rust — stable toolchain + dev tools
          # ──────────────────────────────────────────────
          rust = pkgs.mkShell {
            name = "rust";

            buildInputs = with pkgs; [
              # rust-bin comes from rust-overlay; .override lets you bolt on extensions
              (rust-bin.stable.latest.default.override {
                extensions = [
                  "rust-src"       # needed by rust-analyzer for std-lib goto-def
                  "rust-analyzer"  # LSP server
                  "clippy"
                  "rustfmt"
                ];
              })
              bacon  # background cargo check / test runner — like entr for Rust
            ];

            shellHook = ''
              export PS1="\[\033[1;31m\][🦀 rust]\[\033[0m\] \w \$ "
              echo "Rust shell ready — $(rustc --version)"
            '';
          };

          # ──────────────────────────────────────────────
          # 🎯  Kotlin — JDK 23, Kotlin compiler, Gradle
          # ──────────────────────────────────────────────
          kotlin = pkgs.mkShell {
            name = "kotlin";

            buildInputs = with pkgs; [
              jdk23      # Temurin JDK 23
              kotlin     # kotlinc CLI
              gradle     # build tool
            ];

            shellHook = ''
              export PS1="\[\033[1;35m\][🎯 kotlin]\[\033[0m\] \w \$ "
              export JAVA_HOME="${pkgs.jdk23}"
              echo "Kotlin shell ready — $(kotlin -version 2>&1 | head -1)"
            '';
          };

          # ──────────────────────────────────────────────
          # 🐍  Python — 3.12, uv, ruff, ipython
          # ──────────────────────────────────────────────
          python = pkgs.mkShell {
            name = "python";

            buildInputs = with pkgs; [
              python312                       # interpreter
              uv                             # fast pip + venv replacement
              ruff                           # linter + formatter
              python312Packages.ipython      # interactive shell
            ];

            shellHook = ''
              export PS1="\[\033[1;33m\][🐍 python]\[\033[0m\] \w \$ "
              echo "Python shell ready — $(python --version) | uv $(uv --version)"
            '';
          };

        };
      }
    );
}
