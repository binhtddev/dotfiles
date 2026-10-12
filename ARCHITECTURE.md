# ARCHITECTURE

NixOS + Home Manager dotfiles for NixOS hosts ("dotfiles", flake description
"Nix dotfiles of Binh Tran").

## Naming

| Thing | Convention | Examples |
|---|---|---|
| Flake outputs (hosts) | hostname | `atem`, `yugi`, `joey` |
| System module | `nixos/<topic>.nix` | `nixos/plasma.nix`, `nixos/niri.nix` |
| Home module | `home/<topic>.nix` | `home/desktop.nix`, `home/plasma.nix` |
| Host entry | `hosts/<hostname>/{configuration.nix,home.nix,hardware-*.nix}` | `hosts/atem/` |
| Branch | `feature/<topic>` or `fix/<topic>` | `feature/atem` |
| Commit | `<type>(<scope>): <subject>` | `feat(atem): init config` |

## Layout

```
dotfiles/
├── flake.nix              # inputs + outputs
├── Makefile               # `make <host>` = nixos-rebuild + home-manager, system first
├── hosts/<host>/          # per-machine entries (host-specific only)
├── nixos/*.nix            # reusable system modules, host-agnostic
├── home/*.nix             # reusable home modules, host-agnostic
├── overlays/, pkgs/, modules/, hardwares/, assets/
```

## Outputs

- `nixosConfigurations.{joey,yugi,atem}` → `nixos-rebuild switch --flake .#<host>` (root)
- `homeConfigurations.{yugi,atem}` → `home-manager switch --flake .#<host>` (user)
- `packages`, `overlays`, `nixosModules`, `homeManagerModules`, `formatter` (nixfmt-tree)

## Inputs

`nixpkgs` (nixos-26.05) · `home-manager` (release-26.05, follows nixpkgs) ·
`nixos-hardware` · `nixos-wsl` · `plasma-manager` (follows nixpkgs)

## Hosts

| Host | Role | Desktop |
|---|---|---|
| `joey` | WSL | — |
| `yugi` | workstation | niri |
| `atem` | laptop | KDE Plasma 6 + SDDM |

## The two-scope model

```
                  flake.nix
        ┌────────────┴────────────┐
nixosConfigurations.<host>   homeConfigurations.<host>
        │                         │
hosts/<host>/configuration.nix  hosts/<host>/home.nix
        │                         │
   nixos/*.nix                 home/*.nix
        │                         │
nixos-rebuild switch         home-manager switch
      (root)                     (user)
```

Home Manager is standalone, not a NixOS module: the scopes never auto-apply to
each other, and a partial switch is a valid, recoverable state. Glue between
them is session-level only (e.g. `niri.service`, `graphical-session.target`).

## Module rules

- `hosts/<host>/*.nix`: host-specific wiring (imports, hostname, hardware, users).
  Shared module content never goes here.
- `nixos/*.nix`, `home/*.nix`: one topic per file, host-agnostic, no host names.
- Responsibility split — display manager, desktop environment, PAM/polkit,
  portals, Plymouth, kernel/hardware, system packages → system scope;
  user packages, themes, keybindings, user systemd units, dotfiles → home scope.
- Autostart services must be bound to their own session target, not
  `graphical-session.target`, or they start under the wrong desktop.
- `hosts/<host>/hardware-configuration.nix` is generated; never hand-edit.

## Session lifecycle

boot → Plymouth → SDDM (Wayland) → selected session → `graphical-session.target`
→ home-scope user units start. `systemd.user.startServices = "sd-switch"`.
