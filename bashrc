# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Path adjustments ------------------------------------------------------------
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

# Useful constants ------------------------------------------------------------

# Colors
export C_CLR='\[\e[0m\]'
export C_RED='\[\e[0;31m\]'
export C_GREEN='\[\e[0;32m\]'
export C_BLUE='\[\e[0;34m\]'
export C_YELLOW='\[\e[0;33m\]'

# Regexes
alias ls_regexs="env | grep 'REGEX[^=]*' -o"
# Note its a 'dumb' ip regex, accepts 999.999.999.999
export REGEX_IP='\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'

# Fix ls colors for missing / orphaned files
export LS_COLORS="mi=00:or=40;31;01"

# Setup Bash History ----------------------------------------------------------
HISTCONTROL=ignoreboth  # no duplicates/ignore lines starting with space
HISTFILESIZE=  # Unlimited history file
HISTSIZE=  # Unlimited history
HISTTIMEFORMAT="%FT%T%z "
shopt -s histappend  # append to the history file, don't overwrite it

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Set TERM
TERM=xterm-256color

# Setup Prompt ----------------------------------------------------------------
export PROMPT_COMMAND=__prompt_command

log_bash_persistent_history() {
  # Function to log commands to a persistent history file, doesn't suffer from
  # the issues standard bash histroy has. Called as part of the PROMPT_COMMAND
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
    local EXIT="$?"
    log_bash_persistent_history
    local EXIT_COLOR=""

    # Display if were recording with asciinema
    if [[ $ASCIINEMA_REC ]]; then
        local REC="{${C_RED}REC${C_CLR}}"
    else
        local REC=""
    fi

    # Display venv in prompt
    local VENV="${VIRTUAL_ENV}"
    if [ ! -z "$VENV" ]; then
        VENV_NAME=$(basename "${VENV}")
        VENV="(${C_YELLOW}${VENV_NAME}${C_CLR})"
    fi

    # Color exit code if not 0
    if [ $EXIT != 0 ]; then
        local EXIT_COLOR=$C_RED
    fi

    # Show hostname if connected via SSH
    local SSH=''
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || pstree $$ -s | grep ssh -q ; then
        SSH='@\h'
    fi

    if [[ $EUID -ne 0 ]]; then
        local ROOT_COLOR=""
        local ROOT_COLOR_END=""
    else
        local ROOT_COLOR=$C_RED
        local ROOT_COLOR_END=$C_CLR
    fi

    PS1=""
    PS1+="${REC}"
    PS1+="${VENV}"
    PS1+="${ROOT_COLOR}\\u${SSH}${ROOT_COLOR_END}"
    PS1+="[${EXIT_COLOR}${EXIT}${C_CLR}]"
    PS1+=":\\W"
    PS1+="${C_RED}\$${C_CLR}"
    PS1+=" "
}

# Set up editor ---------------------------------------------------------------
export EDITOR='vim'
export VISUAL='vim'

# Setup Virtual Env Wrapper ---------------------------------------------------
export WORKON_HOME=${HOME}/.virtualenvs
# shellcheck disable=SC1094
source /usr/bin/virtualenvwrapper.sh

# Aliases ---------------------------------------------------------------------
# Not in seperate file for ease of deployment

alias gitgraph="git log --graph --full-history --all --oneline --decorate" # full graph
alias gitgraph_one="git log --graph --full-history --oneline" # single branch
alias gitundocommit="echo 'git reset --soft HEAD^'"  # Git how to
alias gitundomerge="echo 'git reset --hard ORIG_HEAD'"  # Git how to
alias grep="grep --color=auto"  # Color for grep
alias egrep="egrep --color=auto"  # Color for egrep
alias ipython="ipython --no-confirm-exit --no-banner --pprint"  # Make ipython nicer
alias less="less -R"  # Fix colors in less
# LC_COLLATE=C makes underscores sort before a
alias ls="LC_COLLATE=C ls --color -lh"
# Nicer mysql output
alias mysql="mysql --auto-rehash --auto-vertical-output"
# Nice'd Bash, spawns a bash process with highest priority
alias nicebash='sudo nice -n -20 bash'
alias packer=packer-io
alias su='sudo bash'  # Rebind su, if su is needed /bin/su
alias sudo='sudo '  # Fixes bash ignoring aliases after sudo
alias tableflip="echo '(╯°□°）╯︵ ┻━┻'"
alias units="units --verbose --one-line"
alias vimm="vim -u NONE"  # Vim without plugins
alias view="vim"  # Use vim for view not vi

# Functions -------------------------------------------------------------------

function gitdiffpull {
    # Prints a diff of a git pull
    branch=$(git branch | grep '\*' | cut --complement -f 1 -d ' ')
    echo "$branch"
    # @{1} gets the previous state of the branch.
    git diff "${branch}@{1}" "${branch}"
}

function cd()
{
    # Change dir then list new directory contents, replaces cd
    # If no args cd to home as cd normally does
    if [ -n "$1" ]; then
        builtin cd "$1";
    else
        builtin cd ~;
    fi
    # If in git repo top level directory print branch
    if [ -d "./.git" ]; then
        GIT_STATUS=$(git branch --color | grep '\*' | cut --complement -f 1 -d ' ')
        echo "Git Branch: ${GIT_STATUS}";
    fi
    ls; # List directory
}

function cdg()
{
    # cd to top level of git repo
    cd "$(git rev-parse --show-toplevel)" || return
}

function cdb ()
{
    # Search CWD for $1 and change to that directory
    # Magic perl, don't touch :(
    # shellcheck disable=SC1117
    # shellcheck disable=SC2027
    RGX="s/(.*"$1"[^\/]*).*$/\1/i"
    NEWPWD=$(pwd | perl -pe "$RGX")
    echo "$NEWPWD"
    cd "$NEWPWD" || return
}

function crontab ()
{
    # Disable crontab -r
    # Replace -r with -e
    /usr/bin/crontab "${@/-r/-e}"
}

function vrecreate ()
{
    # Vagrant recreate, destroy and up $*
    MACHINES=$*
    # We want wordsplitting here
    # shellcheck disable=SC2086
    vagrant destroy -f ${MACHINES} && vagrant up ${MACHINES}
}

function todos ()
{
    # Search for TODO / XXX and print
    echo -e "\\n--- XXXs"
    grep -nr 'XXX'
    echo -e "\\n--- To Dos"
    grep -nr 'TODO'
    echo ""
}

function archwiki-search ()
{
    # Search local copy of arch wiki, requires arch-wiki-docs package
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

    # Take the top 5
    top=$(echo "${ret}" | head -n 5)
    # Multiple lines so can't use var replace
    # shellcheck disable=SC2001
    out=$(echo "${top}" | sed 's|^|file://|')
    echo -e "\\n${out}\\n"
}

function socks_proxy ()
{
    # Create a socks proxy via host $1
    PROXY_HOST=$1
    PORT="${2:-8432}"
    echo "Starting SOCKs proxy, via ${PROXY_HOST} on port ${PORT}"
    # We want client side expansion
    # shellcheck disable=SC2029
    ssh -D "${PORT}" -C -q -N "${PROXY_HOST}"
}

function wwork ()
{
    # Load virtualenv with same name as current dir
    cur_dir=$(pwd)
    venv=$(basename "${cur_dir}")
    workon "${venv}"
}

function dcb ()
{
    # Display clipboard
    echo "|<<<<<<PRIMARY>>>>>>|"
    xclip -selection primary -o;
    echo -e "\\n|<<<<<<SECONDARY>>>>>>|"
    xclip -selection secondary -o;
    echo -e "\\n|<<<<<<CLIPBOARD>>>>>>|"
    xclip -selection clipboard -o;
    echo ""
}
