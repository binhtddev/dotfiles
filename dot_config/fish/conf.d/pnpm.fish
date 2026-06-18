if type -q pnpm
    and not type -q pn
    alias pn="pnpm"
end

set -gx PNPM_INSTALL "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_INSTALL/bin $PATH
    set -gx PATH $PNPM_INSTALL/bin $PATH
    complete -c pn -w pnpm
end
