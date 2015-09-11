# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Add home/bin to PATH
if [ -d $HOME/bin ]; then
    PATH=$PATH:$HOME/bin
fi
# Add /sbin to PATH
if [ -d /sbin ]; then
    PATH=$PATH:/sbin
fi

# ignoreboth
# ignoredups (no duplicates)
# ignorespace (ignore lines starting with space)
HISTCONTROL=ignoreboth

# Unlimited history
export HISTFILESIZE=
export HISTSIZE=

shopt -s histappend     # append to the history file, don't overwrite it

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Set TERM
TERM=xterm-256color

# Setup Prompt
export PROMPT_COMMAND=__prompt_command

function __prompt_command() {
    EXIT="$?"
    EXIT_COLOR=""
    C_RED='\[\e[0;31m\]'
    C_OIB='\[\e[0;100m\]'
    C_CLR='\[\e[0m\]'

    CUR_DIR_NAME=$(basename $(pwd))

    if [ -e $HOME/.virtualenvs/${CUR_DIR_NAME} ]; then
        VENV_BASENAME=$(basename "${VIRTUAL_ENV}")
        if [ "${VENV_BASENAME}" != "${CUR_DIR_NAME}" ]; then
            workon $CUR_DIR_NAME
        fi
    elif [ ! -z $VIRTUAL_ENV ] ; then
        deactivate > /dev/null 2>&1
    fi

    VENV="${VIRTUAL_ENV}"
    if [ ! -z $VENV ]; then
        VENV="(${C_OIB}$(basename ${VENV})${C_CLR})"
    fi


    if [ $EXIT != 0 ]; then
        EXIT_COLOR=$C_RED
    fi

    if [[ $EUID -ne 0 ]]; then
        # Normal User Prompt
        PS1="${VENV}${debian_chroot:+($debian_chroot)}\u[${EXIT_COLOR}${EXIT}${C_CLR}]:\W${C_RED}\$${C_CLR} "
    else
        # Root User Prompt (red)
        PS1="${VENV}${C_RED}${debian_chroot:+($debian_chroot)}\u${C_CLR}[${EXIT_COLOR}${EXIT}${C_CLR}]${C_RED}:\W#${C_CLR} "
    fi
}

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# Set up ssh-agent
if ! pgrep ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh/agent_config
    ssh-add
fi
eval $(<~/.ssh/agent_config) > /dev/null

# Set up editor
export EDITOR='vim'
export VISUAL='vim'

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Setup Virtual Env Wrapper
export WORKON_HOME=${HOME}/.virtualenvs
#export PROJECT_HOME=${HOME}/repos
source /usr/bin/virtualenvwrapper.sh


# --- Aliases ---
# Not in seperate file for ease of deployment

alias units="units --verbose --one-line"

# LC_COLLATE=C makes underscores sort before a
alias ls="LC_COLLATE=C ls --color -lh"
alias la="ls -a"
alias lz="ls -S"
alias lg="ls -a | grep $1"

alias less="less -R"  # Fix colors in less

alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias grepr="grep -inr * -e $1"  # Grep Recursively for arg

alias mysql="mysql --auto-rehash --auto-vertical-output"

alias packer=packer-io

# Git Graphs
alias gitgraph="git log --graph --full-history --all --oneline --decorate" # full graph
alias gitgraph_one="git log --graph --full-history --oneline" # single branch
# Diff after git pull
alias gitdiffpull="git diff master@{1} master"
# Git howtos, echo some useful instructions
# How to merge with rebase
alias gitmergerebase="echo 'git merge master <branch to merge>'"
alias gitundocommit="echo 'git reset --soft HEAD^'"

# Make ipython nicer
alias ipython="ipython --no-confirm-exit --no-banner --classic --pprint"

# Nice'd Bash, spawns a bash process with highest priority
alias nicebash='sudo nice -n -20 bash'

# Rebind su, if su is needed /bin/su
alias su='sudo bash'
alias sudo='sudo ' # Fixes bash ignoring aliases after sudo

# Clear SSH Sockets
alias clear_sockets='rm -r ~/.ssh/sockets/*'

# Local HTTPBIN server https://github.com/Runscope/httpbin
# pip install httpbin
alias run_httpbin='python -m httpbin.core'

# ccat and cless require pip install pygments
alias ccat="pygmentize -g"  # Syntax Highlighted cat
function cless() { pygmentize -g "$1" | less -R; }  # Syntax Highlighted less

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
        GIT_STATUS=$(git branch --color | grep \* | cut --complement -f 1 -d ' ')
        echo "Git Branch: ${GIT_STATUS}";
    fi
    ls; # List directory
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

# Disable crontab -r
function crontab ()
{
    # Replace -r with -e
    /usr/bin/crontab "${@/-r/-e}"
}

# Vagrant recreate
function vrecreate ()
{
    MACHINES=$@
    vagrant destroy -f ${MACHINES} && vagrant up ${MACHINES}
}

# Vagrant startup, start all machines that were running
function vstartup ()
{
    MACHINES=$(vagrant status | grep poweroff | cut -d ' ' -f 1 | tr "\n" " ")
    vagrant up ${MACHINES}
}

# Highlight Pattern
# highlights a pattern in output
# Usage: hlp CMD PATTERN
# commands with args should be in quotes
function hlp ()
{
    CMD=$1
    PATTERN=$2
    ${CMD} 2>&1 | egrep --color "${PATTERN}|$"
}

function todos ()
{
    echo -e "\n--- XXXs"
    grep -nr 'XXX'
    echo -e "\n--- To Dos"
    grep -nr 'TODO'
    echo ""
}
