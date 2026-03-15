# Explore Next

A map of Nix concepts worth learning, starting from scratch.
Ordered roughly from "start here" to "go deeper when ready".

No prior Nix knowledge assumed.

---

## 1. Understand the Nix Language Itself

Before everything else, Nix the language is what makes everything composable.
It's a lazy, purely functional DSL, a kind of "JSON with functions and imports".

- **Nix Pills** — the classic bottom-up walkthrough of how Nix works from first principles:
  https://nixos.org/guides/nix-pills/
- **nix.dev** — modern, opinionated getting-started guide:
  https://nix.dev/
- **Nix language tour** (interactive):
  https://nixlang.wiki/

Key concepts to nail down:
- `let … in` expressions
- attribute sets (`{ }`) vs lists (`[ ]`)
- `with pkgs;` and why it's slightly evil but convenient
- `inherit` shorthand
- string interpolation: `"${pkgs.hello}/bin/hello"`
- lazy evaluation — nothing is computed unless needed

---

## 2. Flake Outputs — What Can a Flake Expose?

A flake is just a function from `inputs` → `outputs`. The schema is documented but not enforced — you can put
anything in `outputs`. The conventional keys are:

| Key                         | What it is                  |
|-----------------------------|-----------------------------|
| `devShells.<system>.<name>` | `nix develop` targets       |
| `packages.<system>.<name>`  | `nix build` targets         |
| `apps.<system>.<name>`      | `nix run` targets           |
| `checks.<system>.<name>`    | `nix flake check` targets   |
| `overlays.<name>`           | Functions to extend nixpkgs |
| `nixosModules.<name>`       | NixOS module contributions  |
| `templates.<name>`          | `nix flake init` templates  |

Reference: https://nixos.wiki/wiki/Flakes#Output_schema

---

## 3. Overlays — Extending nixpkgs

Overlays are how you override or add packages to `pkgs` without forking nixpkgs.
This flake already uses one (`rust-overlay`). Understanding how to *write* one unlocks a lot.

```nix
# An overlay that overrides `hello` with a patched version
final: prev: {
  hello = prev.hello.overrideAttrs (old: {
    patches = old.patches ++ [ ./my-patch.patch ];
  });
}
```

- https://nixos.wiki/wiki/Overlays
- https://blog.ielliott.io/nix-overlays/ (really clear practical walkthrough)

---

## 4. `pkgs.mkShell` vs `pkgs.devshell` vs `pkgs.mkShellNoCC`

`mkShell` is the simplest way to build devShells. But there are alternatives worth knowing:

- **devshell** (`numtide/devshell`): adds menus, per-project commands, TOML config:
  https://github.com/numtide/devshell
- **mkShellNoCC**: like `mkShell` but without a C compiler in the default env — useful for pure scripting shells
- **dream2nix**: framework for building language-ecosystem packages (npm, cargo, pip…):
  https://dream2nix.dev/

---

## 5. Pinning & Reproducibility — The Core Nix Superpower

`flake.lock` is your reproducibility guarantee. Learn how it works:

```bash
cat flake.lock   # pinned SHA for every input
nix flake update # update all inputs
nix flake lock --update-input nixpkgs  # update just nixpkgs
```

- https://nixos.wiki/wiki/Flakes#Flake_inputs

---

## 6. `nix develop` Deep Dive

`nix develop` does more than just drop you in a shell:

```bash
nix develop .#rust --command cargo build   # run a command inside the shell
nix develop .#rust --ignore-environment    # ultra-clean shell (no $HOME leakage)
nix develop .#rust --unset PATH            # surgical env control
```

The `shellHook` is just bash that runs after the shell is assembled.
You can source other files, set up git hooks, or print a welcome message.

---

## 7. direnv + nix-direnv (Quality of Life Upgrade)

Once you're comfortable with manual `nix develop`, set up direnv so it's automatic.
nix-direnv caches the shell so it's instant after the first build.

- https://github.com/nix-community/nix-direnv
- https://direnv.net/docs/hook.html

---

## 8. Writing Your First Package (`pkgs.stdenv.mkDerivation`)

A derivation is the primitive Nix concept — it's a recipe to build *anything*.
devShells are built on top of derivations. Understanding `mkDerivation` unlocks packaging.

```nix
pkgs.stdenv.mkDerivation {
  pname = "my-tool";
  version = "0.1.0";
  src = ./.;
  buildPhase = "make";
  installPhase = "make install PREFIX=$out";
}
```

- https://nixos.org/manual/nixpkgs/stable/#chap-stdenv
- **Nix Pills Chapter 6+** for the derivation mental model

---

## 9. Flake Templates (`nix flake init`)

You can turn this `dev-shells` repo into a template library:

```nix
outputs = { ... }: {
  templates.rust = {
    path = ./templates/rust;
    description = "Rust devShell starter";
  };
};
```

Then anyone (including future-you) can run:
```bash
nix flake init -t github:you/dev-shells#rust
```

- https://nixos.wiki/wiki/Flakes#Templates

---

## 10. Binary Caches — Speed Everything Up

Nix builds from source by default, but binary caches serve pre-built derivations.
`cache.nixos.org` is the default. **Cachix** lets you host your own:

```bash
cachix use nix-community  # popular community cache with many extra packages
```

- https://cachix.org/
- https://nix.dev/concepts/binary-cache.html

---

## 11. Community Resources Worth Bookmarking

| Resource                          | What                                         |
|-----------------------------------|----------------------------------------------|
| https://search.nixos.org/packages | Find packages in nixpkgs                     |
| https://search.nixos.org/options  | NixOS module options                         |
| https://mynixos.com/              | Alternative package/option search            |
| https://nixhub.io/                | Find specific package versions               |
| https://flakehub.com/             | Discover community flakes                    |
| https://nixos.wiki/               | Community wiki (variable quality, but broad) |
| https://discourse.nixos.org/      | Official forum — very helpful community      |
| `#nix` on Matrix/IRC              | Real-time help                               |

