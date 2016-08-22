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
# Add /home/markeganfuller/.gem/ruby/2.2.0/bin to PATH
if [ -d /home/markeganfuller/.gem/ruby/2.2.0/bin ]; then
    PATH=$PATH:/home/markeganfuller/.gem/ruby/2.2.0/bin
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

    # Auto find and source venv
    CUR_DIR_NAME=$(basename "$(pwd)")

    if [ -e $HOME/.virtualenvs/${CUR_DIR_NAME} ]; then
        VENV_BASENAME=$(basename "${VIRTUAL_ENV}")
        if [ "${VENV_BASENAME}" != "${CUR_DIR_NAME}" ]; then
            workon $CUR_DIR_NAME
        fi
    elif [ ! -z $VIRTUAL_ENV ] ; then
        deactivate > /dev/null 2>&1
    fi

    # Display venv in prompt
    VENV="${VIRTUAL_ENV}"
    if [ ! -z $VENV ]; then
        VENV="(${C_OIB}$(basename "${VENV})${C_CLR}")"
    fi

    # Color exit code if not 0
    if [ $EXIT != 0 ]; then
        EXIT_COLOR=$C_RED
    fi

    # Show hostname if connected via SSH
    SSH=''
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || pstree $$ -s | grep ssh -q ; then
        SSH='@\h'
    fi

    if [[ $EUID -ne 0 ]]; then
        # Normal User Prompt
        PS1="${VENV}${debian_chroot:+($debian_chroot)}\u${SSH}[${EXIT_COLOR}${EXIT}${C_CLR}]:\W${C_RED}\$${C_CLR} "
    else
        # Root User Prompt (red)
        PS1="${VENV}${C_RED}${debian_chroot:+($debian_chroot)}\u${SSH}${C_CLR}[${EXIT_COLOR}${EXIT}${C_CLR}]${C_RED}:\W#${C_CLR} "
    fi
}

# Set up editor
export EDITOR='vim'
export VISUAL='vim'

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Setup Virtual Env Wrapper
export WORKON_HOME=${HOME}/.virtualenvs
source /usr/bin/virtualenvwrapper.sh


# --- Aliases ---
# Not in seperate file for ease of deployment
alias tableflip="echo '(╯°□°）╯︵ ┻━┻'"
alias units="units --verbose --one-line"

# Vim without plugins
alias vimm="vim -u NONE"

# LC_COLLATE=C makes underscores sort before a
alias ls="LC_COLLATE=C ls --color -lh"

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
function gitdiffpull {
    branch=$(git branch | grep \* | cut --complement -f 1 -d ' ')
    echo $branch
    # @{1} gets the previous state of the branch.
    git diff ${branch}@{1} ${branch}
}

# Git howtos, echo some useful instructions
alias gitundocommit="echo 'git reset --soft HEAD^'"
alias gitundomerge="echo 'git reset --hard ORIG_HEAD^'"

# Make ipython nicer
alias ipython="ipython --no-confirm-exit --no-banner --pprint"

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

function todos ()
{
    echo -e "\n--- XXXs"
    grep -nr 'XXX'
    echo -e "\n--- To Dos"
    grep -nr 'TODO'
    echo ""
}

function archwiki-search ()
{
    SEARCH=$1
    WIKI_LANG='en'
    WIKI_BASEDIR='/usr/share/doc/arch-wiki/html'
    WIKIDIR="${WIKI_BASEDIR}/${WIKI_LANG}/"

    # Remove files with no hits
    # Split out the count for easy sorting
    # Sort by number of hits
    ret=$(grep -irc ${SEARCH} ${WIKIDIR} \
          | grep -v ":0" \
          | sed 's/:\([0-9]\+\)$/ \1/' \
          | sort -t' ' -k 2 -n -r)

    top=$(echo "${ret}" | head -n 5)
    out=$(echo "${top}" | sed 's|^|file://|')
    echo -e "\n${out}\n"
}
