set -gx CARGO_HOME "$HOME/.cargo"
if test -d $CARGO_HOME
    if test -f $CARGO_HOME/env.fish
        source $CARGO_HOME/env.fish
    end
    and not string match -q -- $CARGO_HOME/bin $PATH
    set -gx PATH $CARGO_HOME/bin $PATH
end
