# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Add home/bin to PATH
if [ -d "$HOME/bin" ]; then
    PATH=$PATH:$HOME/bin
fi
# Add /sbin to PATH
if [ -d /sbin ]; then
    PATH=$PATH:/sbin
fi
# Add Ruby gems to PATH
if [ -d "$(ruby -e 'print Gem.user_dir')/bin" ]; then
    PATH="$PATH:$(ruby -e 'print Gem.user_dir')/bin"
fi

# Setup History
HISTCONTROL=ignoreboth  # ignoreboth (no duplicates/gnore lines starting with space)
HISTFILESIZE=  # Unlimited history
HISTSIZE=  # Unlimited history
HISTTIMEFORMAT="%FT%T%z "
shopt -s histappend  # append to the history file, don't overwrite it



# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Set TERM
TERM=xterm-256color

# Setup Prompt
export PROMPT_COMMAND=__prompt_command

log_bash_persistent_history() {
  local hist
  local command_part
  hist=$(history 1 | cut -d ' ' -f2-)  # Get last command and cut hist number
  command_part=$(echo "$hist" | cut -d' ' -f2-)  # Get command from line
  if [ "$command_part" != "$PERSISTENT_HISTORY_LAST" ]; then
    echo "$hist" >> ~/.persistent_history
    export PERSISTENT_HISTORY_LAST="$command_part"
  fi
}

function __prompt_command() {
    EXIT="$?"
    log_bash_persistent_history
    EXIT_COLOR=""
    C_RED='\[\e[0;31m\]'
    C_OIB='\[\e[0;100m\]'
    C_CLR='\[\e[0m\]'

    if [[ $ASCIINEMA_REC ]]; then
        REC="{${C_RED}REC${C_CLR}}"
    else
        REC=""
    fi

    # Display venv in prompt
    VENV="${VIRTUAL_ENV}"
    if [ ! -z "$VENV" ]; then
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
        PS1="${REC}${VENV}\\u${SSH}[${EXIT_COLOR}${EXIT}${C_CLR}]:\\W${C_RED}\$${C_CLR} "
    else
        # Root User Prompt (red)
        PS1="${REC}${VENV}${C_RED}\\u${SSH}${C_CLR}[${EXIT_COLOR}${EXIT}${C_CLR}]${C_RED}:\\W#${C_CLR} "
    fi
}

# Set up editor
export EDITOR='vim'
export VISUAL='vim'

# Setup Virtual Env Wrapper
export WORKON_HOME=${HOME}/.virtualenvs
# shellcheck disable=SC1094
source /usr/bin/virtualenvwrapper.sh

# --- Aliases ---
# Not in seperate file for ease of deployment
alias tableflip="echo '(╯°□°）╯︵ ┻━┻'"
alias units="units --verbose --one-line"

# Vim without plugins
alias vimm="vim -u NONE"
alias view="vim"  # Use vim for view not vi

# LC_COLLATE=C makes underscores sort before a
alias ls="LC_COLLATE=C ls --color -lh"

alias less="less -R"  # Fix colors in less

alias grep="grep --color=auto"
alias egrep="egrep --color=auto"

alias mysql="mysql --auto-rehash --auto-vertical-output"

alias packer=packer-io

# Git Graphs
alias gitgraph="git log --graph --full-history --all --oneline --decorate" # full graph
alias gitgraph_one="git log --graph --full-history --oneline" # single branch

# Diff after git pull
function gitdiffpull {
    branch=$(git branch | grep '\*' | cut --complement -f 1 -d ' ')
    echo "$branch"
    # @{1} gets the previous state of the branch.
    git diff "${branch}@{1}" "${branch}"
}

# Git howtos, echo some useful instructions
alias gitundocommit="echo 'git reset --soft HEAD^'"
alias gitundomerge="echo 'git reset --hard ORIG_HEAD'"

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
        GIT_STATUS=$(git branch --color | grep '\*' | cut --complement -f 1 -d ' ')
        echo "Git Branch: ${GIT_STATUS}";
    fi
    ls; # List directory
}

# cd to top level of git repo
function cdg()
{
    cd "$(git rev-parse --show-toplevel)" || return
}

# Search PWD for dir and change to it
function cdb ()
{
    # Magic perl, don't touch :(
    # shellcheck disable=SC1117
    # shellcheck disable=SC2027
    RGX="s/(.*"$1"[^\/]*).*$/\1/i"
    NEWPWD=$(pwd | perl -pe "$RGX")
    echo "$NEWPWD"
    cd "$NEWPWD" || return
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
    MACHINES=$*
    # We want worksplitting here
    # shellcheck disable=SC2086
    vagrant destroy -f ${MACHINES} && vagrant up ${MACHINES}
}

function todos ()
{
    echo -e "\\n--- XXXs"
    grep -nr 'XXX'
    echo -e "\\n--- To Dos"
    grep -nr 'TODO'
    echo ""
}

# Search local copy of arch wiki
function archwiki-search ()
{
    SEARCH=$1
    WIKI_LANG='en'
    WIKI_BASEDIR='/usr/share/doc/arch-wiki/html'
    WIKIDIR="${WIKI_BASEDIR}/${WIKI_LANG}/"

    # Remove files with no hits
    # Split out the count for easy sorting
    # Sort by number of hits
    ret=$(grep -irc "${SEARCH}" "${WIKIDIR}" \
          | grep -v ":0" \
          | sed 's/:\([0-9]\+\)$/ \1/' \
          | sort -t' ' -k 2 -n -r)

    top=$(echo "${ret}" | head -n 5)
    # Multiple lines so can't use var replace
    # shellcheck disable=SC2001
    out=$(echo "${top}" | sed 's|^|file://|')
    echo -e "\\n${out}\\n"
}

# Create a socks proxy via host $1
function socks_proxy ()
{
    PROXY_HOST=$1
    PORT="${2:-8432}"
    echo "Starting SOCKs proxy, via ${PROXY_HOST} on port ${PORT}"
    # We want client side expansion
    # shellcheck disable=SC2029
    ssh -D "${PORT}" -C -q -N "${PROXY_HOST}"
}

# Load virtualenv with same name as current dir
function wwork ()
{
    cur_dir=$(pwd)
    venv=$(basename "${cur_dir}")
    workon "${venv}"
}

# Display clipboard
function dcb ()
{
    echo "|<<<<<<PRIMARY>>>>>>|"
    xclip -selection primary -o;
    echo -e "\\n|<<<<<<SECONDARY>>>>>>|"
    xclip -selection secondary -o;
    echo -e "\\n|<<<<<<CLIPBOARD>>>>>>|"
    xclip -selection clipboard -o;
    echo ""
}
