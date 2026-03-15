# Nix dev-shell

A first experiment with [Nix Flakes](https://nixos.wiki/wiki/Flakes).

The idea is simple: instead of installing tools globally on your machine, each project gets its own isolated
shell with exactly the tools it needs. You enter the shell, work, exit and nothing is installed system-wide.
The environment is described in code, so it works the same on any machine that has Nix.

In this way Nix makes totally obsolete the use of tons of different version managers (`pyenv`, `rustup`, `asdf`, etc.) 
and global package managers (`npm`, `pipx`, `brew`) simplifying the use of multiple languages and their versions / tools across projects.

This repository is a single `flake.nix` that defines a few of these shells as a starting point.

---

## What's in here

A single `flake.nix` with three dev shells:

| Shell    | Tools                                                      |
|----------|------------------------------------------------------------|
| `rust`   | stable Rust, cargo, rust-analyzer, clippy, rustfmt, bacon  |
| `kotlin` | JDK 23, Kotlin compiler, Gradle                            |
| `python` | Python 3.12, uv, ruff, ipython                             |

Each shell sets a custom prompt so you always know which environment is active.

### A few things worth noticing in `flake.nix`

**`rust-overlay`** is a [community input](https://github.com/oxalica/rust-overlay) that provides a `rust-bin` attribute set. 
This is a cleaner way to pick a specific Rust toolchain and add extensions (like `rust-analyzer` or `rust-src`) declaratively.

**`inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs"`** tells Nix to reuse the same `nixpkgs`
that this flake already has, instead of fetching a second independent copy. This is called
input following and is a common pattern when inputs share a dependency.

**`flake-utils.lib.eachDefaultSystem`** is a small helper that generates outputs for multiple
architectures (`x86_64-linux`, `aarch64-darwin`, etc.) without repeating the same code.
The `flake.lock` file pins every input to an exact commit — that's where the reproducibility guarantee lives.

---

## Prerequisites

Install Nix: https://nixos.org/download/

Then enable flakes and the new CLI commands by adding this to `~/.config/nix/nix.conf`
(create the file if it doesn't exist):

```
experimental-features = nix-command flakes
```

---

## Entering a shell

```bash
nix develop .#rust
nix develop .#kotlin
nix develop .#python
```

The prompt will change to show which environment is active. Exit with `exit` or `Ctrl-D`.

To run a single command inside a shell without entering it interactively:

```bash
nix develop .#python --command python --version
```

---

## Useful commands

```bash
# See all available shells in this flake
nix flake show

# Update all pinned inputs to their latest versions
nix flake update

# Update only nixpkgs
nix flake lock --update-input nixpkgs
```

---

## Adding a new shell

Open `flake.nix` and add a new entry under `devShells`:

```nix
go = pkgs.mkShell {
  name = "go";
  buildInputs = with pkgs; [ go gopls gotools ];
  shellHook = ''
    export PS1="\[\033[1;36m\][🐹 go]\[\033[0m\] \w \$ "
    echo "Go shell ready — $(go version)"
  '';
};
```

Then `nix develop .#go`. The attribute name is the shell name — no registration needed.

---

See [`EXPLORE_NEXT.md`](./EXPLORE_NEXT.md) for a map of Nix concepts worth learning next.
See [`TRY_ALSO.md`](./TRY_ALSO.md) for shell auto-activation with direnv.
