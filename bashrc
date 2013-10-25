# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Add home/bin to PATH
if [ -d $HOME/bin ]; then
    PATH=$PATH:$HOME/bin
fi
# Add /sbin to PATH
PATH=$PATH:/sbin

HISTCONTROL=ignoreboth  # force ignoredups and ignorespace
shopt -s histappend     # append to the history file, don't overwrite it

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Setup Prompt
if [[ $EUID -ne 0 ]]; then
    # Normal User Prompt
    PS1='${debian_chroot:+($debian_chroot)}\u[\j]:\W\e[0;31m$\e[m '
else
    # Root User Prompt (red)
    PS1='\e[0;31m${debian_chroot:+($debian_chroot)}\u[\j]:\W#\e[m '
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

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# --- Aliases ---
# Not in seperate file for ease of deployment

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
alias grepr="grep -inr * -e $1"  # Grep Recursively for arg

# Git Graphs
alias gitgraph="git log --graph --full-history --all --oneline" # full graph
alias gitgraph_one="git log --graph --full-history --oneline" # single branch

# Make ipython nicer
alias ipython="ipython --pprint --no-confirm-exit --no-banner --classic"

# Nice'd Bash, spawns a bash process with highest priority
alias nicebash='sudo nice -n -20 bash'

# Rebind su, if su is needed /bin/su
alias su='sudo bash'

# ccat and cless require pip install pygments
alias ccat="pygmentize -g"  # Syntax Highlighted cat
function cless() { pygmentize -g "$1" | less -R; }  # Syntax Highlighted less

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

# Function to change dir then list, replaces cd
function cd()
{
    # If no args cd to home
    if [ -n "$1" ]; then
        builtin cd "$1";
    else
        builtin cd ~;
    fi
    # If in git repo print branch
    if [ -d "./.git" ]; then
        echo "Git Branch: $(git branch --color | grep \* | cut -f 2 -d ' ')";
    fi
    ls -lh -G; # List directory
}

# cd to top level of git repo
function cdg()
{
    cd "$(git rev-parse --show-toplevel)"
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
if [ -f $HOME/.ssh_aliases ]; then
    source $HOME/.ssh_aliases
fi
