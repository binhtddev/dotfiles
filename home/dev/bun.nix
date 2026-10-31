# Bun comes from its own installer (~/.bun/bin), not from Nix — host configs
# leave `bun` commented out of the package list on purpose. The path is
# prepended, so the local binary wins if a Nix one ever gets enabled too.
#
# Used by the repo's asset generator (`bun run build` → xtask.ts) and by
# anything else that expects bun on PATH.
{
  home.sessionPath = [
    "$HOME/.bun/bin"
  ];
}
