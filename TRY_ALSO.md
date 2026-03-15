# TRY_ALSO — Shell auto-activation with direnv

Once you're comfortable running `nix develop .#<name>` manually, the natural next step is to make it automatic:
enter a directory, the shell activates; leave, it deactivates. That's what [direnv](https://direnv.net/) + [nix-direnv](https://github.com/nix-community/nix-direnv) gives you.

---

## What each piece does

- **direnv** — watches for a `.envrc` file in the current directory and loads/unloads environment variables as you navigate your filesystem.
- **nix-direnv** — a direnv extension that adds a `use flake` command. It evaluates the Nix shell and, importantly, caches the result so activation is instant after the first build.

Without nix-direnv, direnv would re-evaluate the flake on every `cd`, which is slow. nix-direnv makes it practical.

---

## Setup (one time)

**1. Install direnv**

```bash
# macOS
brew install direnv

# or via Nix itself
nix profile add nixpkgs#direnv nixpkgs#nix-direnv
```

**2. Hook direnv into your shell**

Add to `~/.zshrc` (or `~/.bashrc`):

```bash
eval "$(direnv hook zsh)"   # replace zsh with bash if needed
```

Restart your shell or run `source ~/.zshrc`.

**3. Configure nix-direnv**

Tell direnv to use nix-direnv's hooks by adding this to `~/.config/direnv/direnvrc`:

```bash
source /path/to/nix-direnv/share/nix-direnv/direnvrc
```

If you installed via `nix profile`, the path will be something like:
```bash
source "$HOME/.nix-profile/share/nix-direnv/direnvrc"
```

---

## Per-project usage

Create a `.envrc` file at the root of a project:

```bash
# Activate the python shell from this flake
use flake /path/to/dev-shells#python

# Or if the flake lives inside the project itself:
use flake .#python
```

Then run once:

```bash
direnv allow
```

From that point on, `cd`-ing into the directory activates the shell silently.
Leaving the directory restores your previous environment.

---

## Notes

- Don't commit `.envrc` files that contain absolute paths — they'll break on other machines. Use relative paths or a `.envrc.example` template instead.
- The first `direnv allow` after changing `.envrc` is intentional — it's a security prompt so direnv doesn't silently execute arbitrary shell code.
- The nix-direnv cache lives in `.direnv/` in your project root. It's safe to `.gitignore` it.

---

## Going further

- nix-direnv README: https://github.com/nix-community/nix-direnv
- direnv docs: https://direnv.net/docs/hook.html
- A guide to using nix-direnv in practice: https://determinate.systems/posts/nix-direnv
