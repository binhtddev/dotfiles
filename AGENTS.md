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
- plasma-manager `overrideConfig = true` deletes existing KDE rc files on
  activation; keep it off unless the user opts in.
