if status is-interactive
    # fish_helix_key_bindings
    fish_vi_key_bindings
end

if not string match -q -- "$HOME/.local/bin" $PATH
    set -gx PATH "$HOME/.local/bin" $PATH
end

if test -f "$HOME/.local/share/bob/nvim-bin/nvim"
    export EDITOR="$HOME/.local/share/bob/nvim-bin/nvim"
else if type -q nvim
    export EDITOR=nvim
else if type -q helix
    if not type -q hx
        alias hx="helix"
    end
    export EDITOR=helix
else if type -q hx
    export EDITOR=hx
else if type -q nvim
    export EDITOR=nvim
else if type -q vim
    export EDITOR=vim
else if type -q vi
    export EDITOR=vi
end

if test -n "$EDITOR"
    export VISUAL=$EDITOR
end

if type -q bat
    export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
end

export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc

if type -q brave
    export BROWSER=brave
else if type -q brave-browser
    export BROWSER=brave-browser
else if type -q google-chrome-stable
    export BROWSER=google-chrome-stable
end

# bun
set -gx BUN_INSTALL "$HOME/.bun"
if not string match -q -- $BUN_INSTALL/bin $PATH
    set -gx PATH $BUN_INSTALL/bin $PATH
end

# ZVM
set -gx ZVM_INSTALL "$HOME/.zvm/self"
if not string match -q -- $ZVM_INSTALL $PATH
    set -gx PATH $PATH "$HOME/.zvm/bin"
    set -gx PATH $PATH "$ZVM_INSTALL"
end

# moonbit
fish_add_path "$HOME/.moon/bin"
