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
export REGEX_ISO_DATETIME='[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}+[0-9]\{4\}'

# Fix ls colors for missing / orphaned files
export LS_COLORS="mi=00:or=40;31;01"

# Setup Bash History ----------------------------------------------------------
HISTCONTROL=ignoreboth  # no duplicates/ignore lines starting with space
HISTFILESIZE=  # Unlimited history file
HISTSIZE=  # Unlimited history
HISTTIMEFORMAT="%FT%T%z "
# Don't save dangerous commands, have you ever CTRL-Red a reboot?
HISTIGNORE='reboot:poweroff'
shopt -s histappend  # append to the history file, don't overwrite it

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Set TERM
TERM=xterm-256color

# Setup Prompt ----------------------------------------------------------------
export PROMPT_COMMAND=__prompt_command

function log_bash_persistent_history() {
  # Function to log commands to a persistent history file, doesn't suffer from
  # the issues standard bash history has. Called as part of the PROMPT_COMMAND
  local hist
  local command_part
  hist=$(history 1 | sed 's/^ [^ ]*  //')  # Get last command and cut hist number
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
    if [ -n "$VENV" ]; then
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

# Misc Setup ------------------------------------------------------------------
# make journalctl show full log lines, no truncation
export SYSTEMD_LESS=FRXMK
# Use libvirt for vagrant
export VAGRANT_DEFAULT_PROVIDER=libvirt

# Aliases ---------------------------------------------------------------------
# Not in seperate file for ease of deployment

alias gitgraph="git log --graph --full-history --all --oneline --decorate" # full graph
alias gitgraph_one="git log --graph --full-history --oneline" # single branch
alias gitundocommit="echo 'git reset --soft HEAD^'"  # Git how to
alias gitundomerge="echo 'git reset --hard ORIG_HEAD'"  # Git how to

alias nicebash='sudo nice -n -20 bash'  # Nice'd Bash, spawns a bash process with highest priority
alias su='sudo bash'  # Rebind su, if su is needed /bin/su
alias sudo='sudo '  # Fixes bash ignoring aliases after sudo

alias tableflip="echo '(╯°□°）╯︵ ┻━┻'"
alias units="units --verbose --one-line --digits 15 "
alias vimm="vim -u NONE"  # Vim without plugins
alias botchcli="rlwrap botchcli"  # Wrap botchcli with rlwrap

alias reboot="echo 'If you actually meant to kill me, use /sbin/reboot'"
alias poweroff="echo 'If you actually meant to kill me, use /sbin/poweroff'"

alias sshnhk="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"  # SSH with no hostkey checking
alias sshp="ssh -o PreferredAuthentications=keyboard-interactive,password -o PubkeyAuthentication=no"  # SSH with no keys
alias sshcis="ssh -o Kexalgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 -o Hostkeyalgorithms=+ssh-dss -o Ciphers=+aes256-cbc -o Pubkeyauthentication=no -a"  # SSH to ciscos

alias serial_conn='screen /dev/ttyUSB0 9600,cs8'

# Aliases - App options -------------------------------------------------------

# Grep: Ignore .git dirs and enable color
alias egrep="egrep --exclude-dir=.git --color=auto"
alias grep="grep --exclude-dir=.git --color=auto"

alias ipython="ipython --no-confirm-exit --no-banner --pprint"  # Make ipython nicer
alias less="less -R"  # Fix colors in less
alias ls="LC_COLLATE=C ls --color -lh"  # LC_COLLATE=C makes underscores sort before a
alias mysql="mysql --auto-rehash --auto-vertical-output"  # Nicer mysql output
alias rename="perl-rename"  # Use perl-rename, allows regex
alias speedtest="speedtest --exclude 4068"  # Exclude bytemark's server
alias speedtest-cli="speedtest --exclude 4068"  # Exclude bytemark's server
alias view="vim"  # Use vim for view not vi

# Functions -------------------------------------------------------------------

function gitdiffpull() {
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
        builtin cd "$1" || return ;
    else
        builtin cd ~ || return;
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

function cdb()
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

function crontab()
{
    # Disable crontab -r
    # Replace -r with -e
    /usr/bin/crontab "${@/-r/-e}"
}

function vrecreate()
{
    # Vagrant recreate, destroy and up $*
    MACHINES=$*
    # We want wordsplitting here
    # shellcheck disable=SC2086
    vagrant destroy -f ${MACHINES} && vagrant up ${MACHINES}
}

function todos()
{
    # Search for TODO / XXX and print
    echo -e "\\n--- XXXs"
    grep -nr 'XXX'
    echo -e "\\n--- To Dos"
    grep -nr 'TODO'
    echo ""
}

function archwiki-search()
{
    # Search local copy of arch wiki, requires arch-wiki-docs package
    SEARCH=$*
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

function persistent-history()
{
    # Search persistent history for a command
    SEARCH=$*
    grep -i "${SEARCH}" ~/.persistent_history
}

function stc-search()
{
    # Search STC
    SEARCH=$*
    STC_BASE_DIR="${HOME}/repos/mine/stc"
    STC_DOCS_DIR="${STC_BASE_DIR}/docs"
    STC_SITE_DIR="${STC_BASE_DIR}/site"

    # Remove files with no hits
    # Split out the count for easy sorting
    # Sort by number of hits
    ret=$(grep -Iirc "${SEARCH}" "${STC_DOCS_DIR}" \
          | grep -v ":0" \
          | sed 's/:\([0-9]\+\)$/ \1/' \
          | sort -t' ' -k 2 -n -r)

    # Take the top 5
    top=$(echo "${ret}" | head -n 5)
    # Multiple lines so can't use var replace
    # add file://
    # Swap for html version for display (need to search md version to avoid getting menus
    # swap md for html
    # shellcheck disable=SC2001
    out=$(echo "${top}" \
        | sed 's|^|file://|' \
        | sed "s|${STC_DOCS_DIR}|${STC_SITE_DIR}|" \
        | sed "s|.md|.html|"
    )
    echo -e "\\n${out}\\n"
}

function socks_proxy()
{
    # Create a socks proxy via host $1
    PROXY_HOST=$1
    PORT="${2:-8432}"
    echo "Starting SOCKs proxy, via ${PROXY_HOST} on port ${PORT}"
    # We want client side expansion
    # shellcheck disable=SC2029
    ssh -D "${PORT}" -C -q -N "${PROXY_HOST}"
}

function wwork()
{
    # Load virtualenv with same name as current dir
    cur_dir=$(pwd)
    venv=$(basename "${cur_dir}")
    workon "${venv}"
}

function dcb()
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

function tinydns_ipv6()
{
    # Convert IPv6 address into tinydns v6 format
    ipv6calc -q --printfulluncompressed "$@" \
        | tr -d :
}

function ttt()
{
    # Immediately add and start a new task in taskwarrior, designed for
    # immediate context switches

    # Create the new task
    taskid=$(task add "${@}")
    taskid=${taskid//[^0-9]/}  # Strip out task number
    # Stop any active tasks
    task +ACTIVE stop
    # Start new task
    task "${taskid}" start
}

# scp_vagrant <machine> <normal SCP args>
# e.g.
# scp_vagrant centos7 centos7:/srv/bob .
# scp_vagrant centos7 . centos7:/srv/bob
function scp_vagrant()
{
    MACHINE=$1
    shift
    CONFIG="/tmp/.vagrant_scp_conf"

    vagrant ssh-config "${MACHINE}" > "${CONFIG}"
    scp -F "${CONFIG}" "${@}"

    rm "${CONFIG}"
}
