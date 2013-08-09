# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Add home/bin to PATH
if [ -d $HOME/bin ]
then
    PATH=$PATH:$HOME/bin
fi

# don't put duplicate lines in the history.
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
HISTCONTROL=$HISTCONTROL${HISTCONTROL+:}ignoredups
# ... or force ignoredups and ignorespace
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
    PS1='${debian_chroot:+($debian_chroot)}\u[\j]:\W❱ '
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

# Set up editors
export EDITOR='vim'
export VISUAL='vim'

# If login shell run vundle update
if [ -d $HOME/.vim/bundle/vundle ] && shopt -q login_shell; then
    /usr/bin/vim +BundleInstall +qall
    clear
fi

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Function for CD to enable cd then ls (auto)
function cd()
{
    if [ -n "$1" ]; then
        builtin cd "$1";
    else
        builtin cd ~;
    fi
    ls -lh -G;
}

# Aliases
# Not in seperate file for ease
alias cls="echo 'USE CTRL-L IDIOT'"
alias cls2="echo 'USE CTRL-L IDIOT'"
alias clear="echo 'USE CTRL-L IDIOT'"

alias ls="ls -G -lh"
alias la="ls -G -lha"
alias lz="ls -G -lhS"
alias lg="ls -G -lha | grep $1"
alias ls2="/usr/bin/clear; ls"
alias less="less -R"
alias grep="grep --color=auto"

# Nice'd Bash, spawns a bash process with highest priority
alias nicebash='sudo nice -n -20 bash'

# Syntax Highlighted cat / less, requires pip install pygments
alias ccat="pygmentize -g"
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
