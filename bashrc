# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Path adjustments ------------------------------------------------------------
# Add home/bin to PATH
if [ -d "$HOME/bin" ]; then
    PATH=$HOME/bin:$PATH
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
export C_CLR='\e[0m'
export C_RED='\e[0;31m'
export C_GREEN='\e[0;32m'
export C_BLUE='\e[0;34m'
export C_YELLOW='\e[0;33m'
export C_MAGENTA='\e[38;5;201m'
export C_BOLD='\e[1m'

## Colors formatted for prompt
export C_P_CLR='\[\e[0m\]'
export C_P_RED='\[\e[0;31m\]'
export C_P_GREEN='\[\e[0;32m\]'
export C_P_BLUE='\[\e[0;34m\]'
export C_P_MAGENTA='\[\e[38;5;201m\]'
export C_P_YELLOW='\[\e[0;33m\]'
export C_P_BOLD='\[\e[1m\]'

## Colors formatted for sed
export C_S_CLR='\x1b[0m'
export C_S_RED='\x1b[0;31m'
export C_S_GREEN='\x1b[0;32m'
export C_S_BLUE='\x1b[0;34m'
export C_S_YELLOW='\x1b[0;33m'

## Hex colours
export C_H_RED="#FF0000"
export C_H_GREEN="#00FF00"
export C_H_BLUE="#0000FF"
export C_H_MAGENTA="#FF00FF"
export C_H_YELLOW="#FFFF00"
export C_H_GREY="#202020"
export C_H_BLACK="#000000"
export C_H_WHITE="#FFFFFF"
export C_H_OFFWHITE="#AAAAAA"

# Regexes
alias ls_regexs="env | grep 'REGEX[^=]*' -o"
# Note its a 'dumb' ip regex, accepts 999.999.999.999
export REGEX_IP='\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'
export REGEX_ISO_DATETIME='[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}+[0-9]\{4\}'

# Fix ls colors for missing / orphaned files
export LS_COLORS="mi=00:or=40;31;01"

# Settings for cdr function
export CDR_WORK_DIRS=() # Should be overriden in .bashrc_local
export CDR_MY_DIRS=('mine')
export CDR_OTHER_DIRS=('other')

# Setup Bash History ----------------------------------------------------------
HISTCONTROL=ignoreboth  # no duplicates/ignore lines starting with space
HISTFILESIZE=  # Unlimited history file
HISTSIZE=  # Unlimited history
HISTTIMEFORMAT="%FT%T%z "
# Don't save dangerous commands, have you ever CTRL-Red a reboot?
HISTIGNORE='reboot:poweroff'
shopt -s histappend  # append to the history file, don't overwrite it

# Other config ----------------------------------------------------------------
PERSISTENT_HIST_FILE="${HOME}/.persistent_history.sqlite"
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Set TERM
TERM=xterm-256color

# Check dotfiles for local changes (only happens on first run) ----------------

function check_git_dir(){
    dir=$1

    pushd . >> /dev/null
    cd "$dir" || return
    status=$(git status --porcelain)
    if [[ $status != "" ]]; then
        echo "$dir"
        echo -e "${C_YELLOW}$status${C_CLR}"
    fi

    # shellcheck disable=SC2164
    popd >> /dev/null
}

# Check dot files
if [[ -d ${HOME}/repos/mine/dotfiles ]]; then
    for dir in "${HOME}/repos/mine/dotfiles"/*/; do
        check_git_dir "$dir"
    done
fi

# Also check bin
if [[ -d "${HOME}/bin" ]]; then
    check_git_dir "${HOME}/bin"
fi

unset -f check_git_dir  # Not needed after initial run

# Git settings for prompt output
if [[ -f /usr/share/git/completion/git-prompt.sh ]]; then
    source /usr/share/git/completion/git-prompt.sh
fi
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1

# Setup Prompt ----------------------------------------------------------------
export PROMPT_COMMAND=__prompt_command

function log_bash_persistent_history() {
    # Sqlite logging of commands
    # Table creation
    # CREATE TABLE history (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, number INTEGER, datetime TEXT, command TEXT, return_code INTEGER, pwd TEXT, pid INTEGER);
    # Table column addition
    # ALTER TABLE history ADD COLUMN pwd TEXT DEFAULT '';

    local hist
    local number
    local datetime
    local command
    local return_code=$1
    local pwd=$PWD
    local pid=$$

    # position 1 may be a space, this condenses multiple spaces to signle and
    # strips spaces at the start
    hist=$(history 1 | tr -s ' ' | sed 's/^ //')
    number=$(echo "${hist}" | cut -d' ' -f1)
    datetime=$(echo "${hist}" | cut -d' ' -f2)
    command=$(echo "${hist}" | cut -d' ' -f3-)

    # Double single quoting stuff fixes escaping issues, not sure why? TODO
    command=${command//\'/''/}

    sqlite3 "${PERSISTENT_HIST_FILE}" <<EOF
.timeout 5000
INSERT INTO history (number, datetime, command, return_code, pwd, pid)
VALUES (${number}, '${datetime}', '${command}', ${return_code}, '${pwd}', ${pid});
EOF
}


function __prompt_command() {
    local EXIT="$?"
    log_bash_persistent_history $EXIT

    # Display if were recording with asciinema
    if [[ $ASCIINEMA_REC ]]; then
        local REC="{${C_P_RED}REC${C_P_CLR}}"
    else
        local REC=""
    fi

    # Display venv in prompt
    local VENV="${VIRTUAL_ENV}"
    if [ -n "$VENV" ]; then
        VENV_NAME=$(basename "${VENV}")
        VENV="(${C_P_YELLOW}${VENV_NAME}${C_P_CLR})"
    fi

    # Show exit code if not 0
    if [ $EXIT != 0 ]; then
        local EXIT_STR="[${C_P_RED}${EXIT}${C_P_CLR}]"
    else
        local EXIT_STR=""
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
        local ROOT_COLOR=$C_P_RED
        local ROOT_COLOR_END=$C_P_CLR
    fi

    # If in or below ~/repos/*test flag that we're in test
    if [[ $(pwd) =~ ${HOME}/repos/[^/]*test(/|$) ]]; then
        local TEST="${C_P_MAGENTA}[T]${C_P_CLR}"
    else
        local TEST=""
    fi

    PS1=""
    PS1+="${EXIT_STR}"
    PS1+="${REC}"
    PS1+="${VENV}"
    PS1+="${ROOT_COLOR}\\u${SSH}${ROOT_COLOR_END}"
    PS1+=":"
    PS1+="$TEST"
    PS1+="${C_P_YELLOW}$(__git_ps1 "(%s)")${C_P_CLR}"
    PS1+="\\W"
    PS1+="${C_P_RED}\$${C_P_CLR}"
    PS1+=" "
}

# Set up editor ---------------------------------------------------------------
export EDITOR='vim'
export VISUAL='vim'

# Setup Virtual Env Wrapper ---------------------------------------------------
export WORKON_HOME=${HOME}/.virtualenvs
# shellcheck disable=SC1094
if [[ -e /usr/bin/virtualenvwrapper.sh ]]; then
    # For Arch
    source /usr/bin/virtualenvwrapper.sh
elif [[ -e /usr/local/bin/virtualenvwrapper.sh ]]; then
    # For Ubuntu
    export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
    source /usr/local/bin/virtualenvwrapper.sh
fi

# Misc Setup ------------------------------------------------------------------
# make journalctl show full log lines, no truncation
export SYSTEMD_LESS=FRXMK
# Use libvirt for vagrant
export VAGRANT_DEFAULT_PROVIDER=libvirt
# FZF include hidden files
export FZF_DEFAULT_COMMAND="fd --type f --hidden"

FZF_DEFAULT_OPTS="--reverse --preview"
FZF_DEFAULT_OPTS+=" 'head -n 30 {} | pygmentize -O style=monokai'"
FZF_DEFAULT_OPTS+=" --preview-window down "
FZF_DEFAULT_OPTS+="--color=bg+:${C_H_GREY},bg:${C_H_BLACK},border:${C_H_GREY}"
FZF_DEFAULT_OPTS+=",spinner:${C_H_MAGENTA},hl:${C_H_MAGENTA}"
FZF_DEFAULT_OPTS+=",header:${C_H_YELLOW},info:${C_H_GREY},prompt:${C_H_WHITE}"
FZF_DEFAULT_OPTS+=",gutter:${C_H_BLACK},fg+:${C_H_OFFWHITE}"
FZF_DEFAULT_OPTS+=",hl+:${C_H_MAGENTA},pointer:${C_H_MAGENTA}"
export FZF_DEFAULT_OPTS

# Aliases ---------------------------------------------------------------------
# Not in seperate file for ease of deployment
alias nicebash='sudo nice -n -20 bash'  # Nice'd Bash, spawns a bash process with highest priority
alias su='sudo bash'  # Rebind su, if su is needed /bin/su
alias sudo='sudo '  # Fixes bash ignoring aliases after sudo

alias tableflip="echo '(╯°□°）╯︵ ┻━┻'"
alias shrug="echo '¯\_(ツ)_/¯'"
alias units="units --verbose --one-line --digits 15 "
alias vimm="vim -u NONE"  # Vim without plugins
alias botchcli="rlwrap botchcli"  # Wrap botchcli with rlwrap

alias reboot="echo 'If you actually meant to kill me, use /sbin/reboot'"
alias poweroff="echo 'If you actually meant to kill me, use /sbin/poweroff'"

alias sshnhk="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"  # SSH with no hostkey checking
alias sshp="ssh -o PreferredAuthentications=keyboard-interactive,password -o PubkeyAuthentication=no"  # SSH with no keys
# SSH to ciscos
alias sshcis="ssh -o Kexalgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 -o Hostkeyalgorithms=+ssh-dss,ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o Ciphers=+aes256-cbc -o Pubkeyauthentication=no -a"
alias serial_conn='screen /dev/ttyUSB0 9600,cs8'

# Audio alert for when a long running task finishes
alias bp='spd-say "Alert: Command ended, Exit code: $?"'

# Aliases - App options -------------------------------------------------------

# Grep: Ignore .git dirs and enable color
alias grep="grep --exclude-dir=.git --color=auto"
alias ggrep="git grep"

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

# TODO: RVM breaks this because it has its own CD function
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

function cdr_preview() {
    # some helper text
    echo -e "${C_RED}'${C_CLR}exact | ${C_RED}^${C_CLR}prefix-exact | suffix-exact${C_RED}\$${C_CLR} | ${C_RED}!${C_CLR}inverse-exact | ${C_RED}!^${C_CLR}inverse-prefix-exact | ${C_RED}!${C_CLR}inverse-suffix-exact${C_RED}\$${C_CLR}"
    echo -e "_______________________________________\n"

    path="${*}"
    cd "$path" || exit
    if [[ $path =~ ${HOME}/repos/[^/]*test(/|$).* ]]; then
        echo -n -e "$C_MAGENTA"
    fi
    pwd
    echo -e "${C_BOLD}${C_YELLOW}"
    git remote get-url origin | sed 's|.*/\([^/]*\)\(.git\)*$|\1|';
    echo -e "${C_CLR}"
    git -c color.status=always status
}

function cdr() {
    # Change directory to a repository

    export -f cdr_preview
    local repo_dir="${HOME}/repos"

    # Any dir under repos/*/
    local dirs
    dirs=$(fd --hidden --no-ignore --no-ignore-vcs --regex '^.git$' \
        --exclude extmodules "${repo_dir}" --exec dirname \
        | sort -u
    )

    # This mess is to ensure work stuff sorts first
    # Note if theres another directory under repos it *WON'T* be searched
    # Work repos
    local work_dirs=()
    for d in "${CDR_WORK_DIRS[@]}"; do
        mapfile -t -O "${#work_dirs[@]}" work_dirs \
            < <(echo "$dirs" | grep "${repo_dir}/${d}/")
    done

    # Then my repos
    local my_dirs=()
    for d in "${CDR_MY_DIRS[@]}"; do
        mapfile -t -O "${#my_dirs[@]}" my_dirs \
            < <(echo "$dirs" | grep "${repo_dir}/${d}/")
    done

    # Then other repos
    local other_dirs=()
    for d in "${CDR_OTHER_DIRS[@]}"; do
        mapfile -t -O "${#other_dirs[@]}" other_dirs \
            < <(echo "$dirs" | grep "${repo_dir}/${d}/")
    done

    local dirs_ordered=("${work_dirs[@]}")
    dirs_ordered+=("${my_dirs[@]}")
    dirs_ordered+=("${other_dirs[@]}")

    target=$(printf "%s\n" "${dirs_ordered[@]}" \
        | grep -v "z_dummy_worktree_branch_z" \
        | fzf \
            --preview-window down \
            --delimiter='/' \
            --nth=-2.. \
            --no-sort \
            --preview ". ~/.bashrc && cdr_preview {}" \
            --header="cdr"
    )

    if [[ -n $target ]]; then
        cd "$target" || return
    fi
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
    sqlite3 "${PERSISTENT_HIST_FILE}" \
        "SELECT * FROM history WHERE command LIKE '%${SEARCH}%';" \
        | grep "$SEARCH"
}

function stc-search()
{
    # TODO Use fzf with preview
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
        | sed "s|.md\s|.html |"
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

function check_ssl_server()
{
    TARGET=$1
    PORT=${2:-443}
    echo ''\
        | openssl s_client -showcerts -servername "${TARGET}" -connect "${TARGET}:${PORT}" 2>/dev/null \
        | openssl x509 -inform pem -noout -text
}

# fzf CD (jumps to homedir first and searches from there)
function cdf()
{
    builtin cd "${HOME}" || return
    target=$(fd --type d --hidden --follow \
        | fzf --reverse \
              --preview "ls {}" \
              --preview-window down \
              --header="cdf"
    )
    if [[ -n $target ]]; then
        cd "$target" || return
    fi
}

# fzf local CD
function cdff()
{
    target=$(fd --type d --hidden --follow \
        | fzf --reverse \
              --preview "ls {}" \
              --preview-window down \
              --header="cdff"
    )
    if [[ -n $target ]]; then
        cd "$target" || return
    fi
}

# fzf CD scratchpads (jumps to scratchpads first and searches from there)
function cds()
{
    builtin cd "${HOME}/scratchpads" || return
    target=$(fd --type d --hidden --follow \
        | fzf --reverse \
              --preview "ls {}" \
              --preview-window down \
              --header="cds"
    )
    if [[ -n $target ]]; then
        cd "$target" || return
    fi
}


# fzf vim
function vf()
{
    target="$(fzf)"
    if [[ -n $target ]]; then
        absolute=$(realpath "${target}")
        cd "$(dirname "${target}")" || exit 1
        # If we're in a git repo its nicer to be at the top level
        cdg
        vim "${absolute}"
    fi
}

# Get SSH hosts from SSH config, known hosts etc
function get_ssh_hosts() {
    # Taken from fzf bash completion and adjusted
    # https://github.com/junegunn/fzf/blob/master/shell/completion.bash#L284
    {
    tail -n +1 ~/.ssh/config ~/.ssh/config.d/* /etc/ssh/ssh_config 2> /dev/null \
        | grep -i '^\s*host\(name\)\? ' \
        | awk '{for (i = 2; i <= NF; i++) print $1 " " $i}' \
        | grep -v '[*?]' ;\
    grep -oE '^[[a-z0-9.,:-]+' ~/.ssh/known_hosts \
        | tr ',' '\n' \
        | tr -d '[' \
        | awk '{ print $1 " " $1 }' ;\
    grep -v '^\s*\(#\|$\)' /etc/hosts \
        | grep -Fv '0.0.0.0' ;\
    } | awk '{if (length($2) > 0) {print $2}}' | sort -u
}

# fzf ssh()
function sshfzf()
{
    target=$(get_ssh_hosts | FZF_DEFAULT_OPTS='--reverse' fzf)
    if [[ -n $target ]]; then
        ssh "$target"
    fi
}

function h_preview() {
    # some helper text
    echo -e "${C_RED}'${C_CLR}exact | ${C_RED}^${C_CLR}prefix-exact | suffix-exact${C_RED}\$${C_CLR} | ${C_RED}!${C_CLR}inverse-exact | ${C_RED}!^${C_CLR}inverse-prefix-exact | ${C_RED}!${C_CLR}inverse-suffix-exact${C_RED}\$${C_CLR}"
    echo -e "_______________________________________\n"

    command="${*}"
    command=$(echo "${command}" | sed "s/'/''/g")
    sqlite3 "${PERSISTENT_HIST_FILE}" -header -column "SELECT * FROM history WHERE command LIKE '${command}%' ORDER BY id DESC"
}

# fzf Persistent history
function h() {
    export PERSISTENT_HIST_FILE C_CLR C_BLUE
    export -f h_preview

    command=$(sqlite3 "${PERSISTENT_HIST_FILE}" \
        "SELECT DISTINCT command FROM history ORDER BY id DESC;" \
        | FZF_DEFAULT_OPTS="--reverse --preview '. ~/.bashrc && h_preview {}' --preview-window down --no-mouse" fzf)
    echo "$command"
}

# Shortcut to list worktrees, with some color
function gwt(){
    # Hide dummy branch
    # Color branch
    git worktree list \
        | grep -v z_dummy_worktree_branch_z \
        | sed -e "s/\[/${C_S_YELLOW}/" -e "s/\]/${C_S_CLR}/"
}

# CD to main/master (default) branch for worktree
function cdm(){
    local main_branch_name
    main_branch_name=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
    local dir
    dir=$(git worktree list \
        | grep "\[${main_branch_name}\]" \
        | awk '{print $1}')

    cd "$dir" || return
}

# CD to another worktree
function cdw(){
    target=$(
        git worktree list \
        | grep -v z_dummy_worktree_branch_z \
        | awk '{print $1}' \
        | fzf --preview "cd {};  git -c color.status=always status" \
              --preview-window down
    )
    if [[ -n $target ]]; then
        cd "$target" || return
    fi
}

# Setup a branch with worktrees
function gwt_branch() {
    # Assumes you're in a worktree git repo
    local branch=$1

    # Jump to the top level git dir
    cdg || return

    if ! git branch --all | grep "$branch" -q ; then
        # Branch doesn't exist so create
        git worktree add "../${branch}" -b "$branch"
    else
        git worktree add "../${branch}" "$branch"
    fi

    cd "../${branch}" || return
}

# Clone a repo for use with worktrees
function gwt_clone() {
    local url=$1
    local dir=$2

    if [ "$#" -ne 2 ]; then
        echo "Usage: gwt_clone <url> <directory>"
        return 1
    fi

    mkdir "$dir" || return 1
    cd "$dir" || return 1
    git clone "$url" z_dummy_worktree_branch_z

    cd z_dummy_worktree_branch_z || exit 1
    local main_branch_name
    main_branch_name=$(git branch | awk '{print $2}')

    git checkout -b z_dummy_worktree_branch_z
    gwt_branch "$main_branch_name"
}

# Open in browser
function oib {
    if [[ $# -gt 0 ]]; then
        firefox "file://${PWD}/${1}"
    else
        firefox "file://${PWD}"
    fi
}

# -----------------------------------------------------------------------------
# Finally load any local config (Used for machine or work specific stuff)
if [[ -e "${HOME}/.bashrc_local" ]]; then
    source "${HOME}/.bashrc_local"
fi
