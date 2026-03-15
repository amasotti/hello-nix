# Storage, Cleanup, and Uninstalling Nix

---

## How the Nix store works

Everything Nix builds or downloads lives in `/nix/store`. Each item in the store is a directory
named with a hash of its inputs:

```
/nix/store/xxxxxxxx-python3-3.12.0/
/nix/store/yyyyyyyy-cargo-1.76.0/
/nix/store/zzzzzzzz-rust-analyzer-2024-02-05/
```

The hash changes if *anything* about the build changes (version, dependencies, build flags).
This is what makes Nix reproducible — two builds with the same inputs produce the same hash
and land at the same path.

**The key point about storage:** Nix deduplicates across everything on the machine.
If your `rust` shell and a separate project both use the same version of `rust-analyzer`,
there is exactly one copy in the store, referenced by both. You are not paying for it twice.
The store is shared across all your profiles, all your shells, all your projects.

What *does* grow over time: old versions. When you run `nix flake update`, Nix fetches the
new packages but keeps the old ones around — they might still be referenced by a rollback point
or another project. That accumulation is what `nix store gc` addresses (see below).

### How much space to expect

A typical initial `nix develop` for a shell will download and build its closure — the shell
itself plus all its dependencies. Roughly speaking, you can expect something like this:

| Shell    | Approximate closure size  |
|----------|---------------------------|
| `python` | ~500 MB                   |
| `rust`   | ~2–3 GB (compiler + std)  |
| `kotlin` | ~1–2 GB (JDK + toolchain) |

After the first run, subsequent `nix develop` calls are instant — everything is cached.
Running multiple shells does not multiply disk usage for shared dependencies.

To inspect the exact size of a shell's closure before building:

```bash
nix path-info --recursive --size .#devShells.aarch64-darwin.python 2>/dev/null | \
  awk '{sum += $2} END {printf "%.0f MB\n", sum/1024/1024}'
```

---

## Checking what's in the store

```bash
# Total size of the Nix store
du -sh /nix/store

# See what's currently reachable (won't be deleted by GC)
nix-store --query --roots /nix/store/*  # slow on a big store

# List store paths sorted by size (top 20)
nix path-info --all -S 2>/dev/null | sort -k2 -n | tail -20
```

---

## Garbage collection

Nix has a garbage collector. It deletes store paths that are no longer referenced by any
*GC root* — a GC root is anything that "holds on" to a store path: your current shell profile,
a `result` symlink from `nix build`, a running process, or a direnv cache.

```bash
# Dry run — shows what would be deleted without deleting anything
nix store gc --dry-run

# Delete all unreferenced store paths
nix store gc

# Older-style equivalent (same thing)
nix-collect-garbage
```

**More aggressive cleanup:**

```bash
# Delete all old generations of your profile (rollback points), then GC
nix-collect-garbage --delete-old

# Same but also wipe generations older than N days
nix-collect-garbage --delete-older-than 30d
```

After running GC you can reclaim significant space if you've updated inputs a few times
or experimented with many shells.

### The `result` symlink

When you run `nix build`, Nix creates a `./result` symlink in your working directory.
That symlink is a GC root — meaning the thing it points to will never be garbage collected
as long as the symlink exists. If you have stale `result` symlinks in old project directories,
they're keeping packages alive.

```bash
# Find all result symlinks on your machine
find ~ -name "result" -type l 2>/dev/null

# Remove one to let GC reclaim its packages
rm ./result
```

---

## Wiping a specific flake's downloads

There is no "uninstall this project's packages" command — the store is global and shared.
The right approach is to let GC handle it: once you have no active shells, no `result` symlinks,
and no direnv `.direnv/` caches pointing to this flake's packages, running `nix store gc`
will reclaim the space.

If you use nix-direnv, the `.direnv/` directory in a project holds GC roots for that shell.
Remove it to release the hold:

```bash
rm -rf .direnv/
nix store gc
```

---

## Completely uninstalling Nix

This depends on how Nix was installed.

### If installed with the official installer (single-user or multi-user)

The official uninstall instructions are at:
https://nixos.org/manual/nix/stable/installation/uninstall.html

The short version for macOS (multi-user install, which is the default):

```bash
# 1. Remove the Nix daemon launchd service
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist

# 2. Remove the store volume (on macOS, Nix lives on a separate APFS volume)
sudo diskutil apfs deleteVolume /nix

# 3. Remove the /nix mount point and leftover files
sudo rm -rf /etc/nix /var/root/.nix-profile /var/root/.nix-defexpr
sudo rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix

# 4. Remove the nixbld users and group
for i in $(seq 1 32); do sudo dscl . delete /Users/nixbld$i 2>/dev/null; done
sudo dscl . delete /Groups/nixbld 2>/dev/null

# 5. Undo /etc/zshrc and /etc/bashrc modifications Nix made during install
# Look for lines between "# Nix" and "# End Nix" and remove them
```

> The exact steps vary slightly by macOS version and Nix installer version.
> Always check the official docs link above before running, as it's kept up to date.

---

## Summary

| Concern                                 | Answer                                                           |
|-----------------------------------------|------------------------------------------------------------------|
| Are packages duplicated across shells?  | No — the store deduplicates by content hash                      |
| Does updating inputs waste space?       | Old versions accumulate, `nix store gc` reclaims them            |
| How do I free space right now?          | `nix-collect-garbage --delete-old`                               |
| How do I release space for one project? | Remove `.direnv/` and `result` symlinks, then run `nix store gc` |
| How do I get rid of Nix entirely?       | Depends on installer — see uninstall section above               |
