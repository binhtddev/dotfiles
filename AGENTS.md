# AGENTS

For how this project is structured, read [ARCHITECTURE.md](./ARCHITECTURE.md)
first. This file covers how to work in it.

## Rules

1. Know which scope you are changing (system vs home) — see ARCHITECTURE.md.
   Each change is applied by its own command; system first, then home.
2. Change one host at a time. Do not touch `hosts/yugi/` when working on `atem`,
   or vice versa.
3. Never run `switch` (or `make`) without asking. Dry-run first:
   - `nixos-rebuild build --flake .#<host>`
   - `home-manager build --flake .#<host>`
4. Commit or stash WIP before starting; one logical change per commit.
5. Format with `nix fmt`, lint with `statix`.

## Workflow

- Verify → build both scopes → ask → switch system → switch home → verify session.
- If a session-scoped service misbehaves under the other desktop, the cause is
  almost always its `Install.WantedBy`.

## Gotchas

- `flake.lock` is shared by every host; updating it rebuilds all of them.
- nixpkgs and home-manager pins must stay on matching channels.
- Two plain definitions of the same option (e.g. `qt.style.name`) are an eval
  conflict — override from the host's module with `lib.mkForce`.

## Plasma

The desktop configuration (themes, kwin, power, locker, input, shortcuts,
panel/tray applets) is **not** declarative — `plasma-manager` was removed on
purpose. It lives in `plasma/setup.sh`:

- `./plasma/setup.sh` — applies once; an empty lock at
  `~/.local/state/plasma/setup.lock` means "already applied"
- `./plasma/setup.sh --force` — applies again (also bound to `Alt+Shift+Space`)
- `./plasma/setup.sh --check` — reads every value back, exits non-zero on drift
- `./plasma/setup.sh --dump` — current values, useful after a Plasma upgrade

Rules for it:

- run it only inside a live Plasma session (theme/applet steps need DBus);
  without one it writes the config keys and exits 1 without taking the lock
- `home/plasma.nix` keeps only packages, the wallpaper file and GTK/Kvantum —
  do not reintroduce `programs.plasma.*`
- system-level settings (SDDM, services, kernel params) belong in `nixos/*.nix`
  and `nixos-rebuild`; a rebuild would overwrite anything written to `/etc`
