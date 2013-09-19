# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Add home/bin to PATH
if [ -d $HOME/bin ]
then
    PATH=$PATH:$HOME/bin
fi

# force ignoredups and ignorespace
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Setup Prompt, if root use a RED prompt
if [[ $EUID -ne 0 ]];
then
    # Normal User Prompt
    PS1='${debian_chroot:+($debian_chroot)}\u[\j]:\W\e[0;31m❱\e[m '
else
    # Root User Prompt
    PS1='\e[0;31m${debian_chroot:+($debian_chroot)}\u[\j]:\W❱\e[m '
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# Set up editor
export EDITOR='vim'
export VISUAL='vim'

# Technically I shouldn't force this...
export TERM=xterm-256color

# If login shell run vundle update
if [ -d $HOME/.vim/bundle/vundle ] && shopt -q login_shell; then
    /usr/bin/vim +BundleInstall +qall
    clear
fi

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# --- Aliases ---
# Not in seperate file for ease

# So I finally discovered CTRL-L
alias cls="echo 'USE CTRL-L IDIOT'"
alias cls2="echo 'USE CTRL-L IDIOT'"
alias clear="echo 'USE CTRL-L IDIOT'"

# Note, on mac -G is for color on linux --color is for color.
# Since I'm stuck on a mac FTM leaving it as -G
alias ls="ls -G -lh"
alias la="ls -G -lha"
alias lz="ls -G -lhS"
alias lg="ls -G -lha | grep $1"
alias less="less -R"  # Fix colors in less
alias grep="grep --color=auto"
alias grepr="grep -inr $1 *"  # Grep Recursively for $1 #FIXME

alias gitgraph="git log --graph --full-history --all --oneline" # Show brnahc graph

# Make Python a bit cleaner
export PYTHONDONTWRITEBYTECODE=1

# Make ipython nicer
alias ipython="ipython --pprint --no-confirm-exit --no-banner --classic"

# Nice'd Bash, spawns a bash process with highest priority
alias nicebash='sudo nice -n -20 bash'

# Rebind su, if su is needed /bin/su
alias su='sudo bash'

# These require pip install pygments
# Syntax Highlighted cat
alias ccat="pygmentize -g"

# Syntax Highlighted less
function cless()
{
    pygmentize -g "$1" | less -R;
}

# i3 vim alias
# Changes i3 Borders when entering / exiting vim
if hash i3-msg >/dev/null 2>&1; then
    function vim() {
        i3-msg border 1pixel >/dev/null 2>&1;
        /usr/bin/vim "$@";
        i3-msg border normal >/dev/null 2>&1;
    }
else
    alias vim="vim"
fi

# Function to change dir then list replaces cd
function cd()
{
    # Handle cd with/out args
    if [ -n "$1" ]; then
        builtin cd "$1";
    else
        builtin cd ~;
    fi
    # If in git repo print branch
    if [ -d "./.git" ]; then
        echo "Git Branch: $(git branch --color | grep \* | cut -f 2 -d ' ')";
    fi
    # List directory
    ls -lh -G;
}

# cd to top level of git repo
function cdg()
{
    builtin cd "$(git rev-parse --show-toplevel)"
    ls -lh -G;
}

# Search PWD for dir and change to it
function cdb ()
{
    RGX="s/(.*"$1"[^\/]*).*$/\1/i"
    NEWPWD=$(pwd | perl -pe "$RGX")
    echo $NEWPWD
    cd "$NEWPWD"
}

# Add ssh aliases
if [ -f $HOME/.ssh_aliases ]
then
    source $HOME/.ssh_aliases
fi
