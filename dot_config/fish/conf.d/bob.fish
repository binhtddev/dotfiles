set -l BOB_HOME "$HOME/.local/share/bob"
if not string match -q -- "$BOB_HOME/nvim-bin" $PATH
    set -gx PATH "$BOB_HOME/nvim-bin" $PATH
end
