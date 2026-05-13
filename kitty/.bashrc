# ════════════════════════════════════════════════════════════════
#  ~/.bashrc — Mukul's Dev Environment
#  Stack : Java · TypeScript · Node.js · Python · CUDA
#  Shell : Bash + ble.sh  |  Term: Kitty + Hyprland
#
#  Symlink layout (run setup-dotfiles.sh once to wire this up):
#    ~/Main/dotfiles/bashrc  ← source of truth (edit here)
#    ~/.bashrc               → symlink
#    ~/.config/hypr/.bashrc  → symlink
# ════════════════════════════════════════════════════════════════

# ── Guard: non-interactive shells get nothing ─────────────────
case $- in
    *i*) ;;
    *) return;;
esac

# ════════════════════════════════════════════════════════════════
#  SHELL OPTIONS
# ════════════════════════════════════════════════════════════════
shopt -s checkwinsize   # recheck terminal size after each command
shopt -s globstar       # ** glob works recursively
shopt -s autocd         # bare directory name → cd into it
shopt -s cdspell        # fix minor typos in cd paths
shopt -s direxpand      # expand dir names on tab
shopt -s histappend     # append to history file, never overwrite
shopt -s cmdhist        # save multi-line commands as one history entry

# ════════════════════════════════════════════════════════════════
#  HISTORY
# ════════════════════════════════════════════════════════════════
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups        # no dupes, ignore space-prefixed lines
HISTTIMEFORMAT="%Y-%m-%d %H:%M  "
HISTIGNORE="ls:ll:la:cd:cd -:pwd:clear:exit:history:bg:fg"

# Sync history across all open terminals after every command
_history_sync() { history -a; history -c; history -r; }
PROMPT_COMMAND="_history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ════════════════════════════════════════════════════════════════
#  FASTFETCH
# ════════════════════════════════════════════════════════════════
command -v fastfetch &>/dev/null && fastfetch

# ════════════════════════════════════════════════════════════════
#  BLE.SH
# ════════════════════════════════════════════════════════════════
source /usr/share/blesh/ble.sh 2>/dev/null || true

# ble.sh config: use bleopt and ble-color-defface — NOT env vars.
bleopt complete_menu_style=desc
bleopt exec_errexit_mark='[exit %d] '
# ble-color-defface command_builtin fg=green   # uncomment to customise

# ════════════════════════════════════════════════════════════════
#  ENVIRONMENT
# ════════════════════════════════════════════════════════════════
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-RFX'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export MANPAGER='nvim +Man!'   # open man pages in nvim

# ════════════════════════════════════════════════════════════════
#  PATH — built once, highest priority first, no duplicates
# ════════════════════════════════════════════════════════════════
path_prepend() {
    [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/Main/DSA"
path_prepend "$HOME/.npm-global/bin"
path_prepend "$HOME/.yarn/bin"

# ════════════════════════════════════════════════════════════════
#  JAVA
# ════════════════════════════════════════════════════════════════
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
# export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
path_prepend "$JAVA_HOME/bin"
export JAVA_OPTS="-Xms512m -Xmx2048m"

# ════════════════════════════════════════════════════════════════
#  NODE — use NVM or Volta, not both
# ════════════════════════════════════════════════════════════════

# --- NVM (active) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# --- Volta (comment NVM block above and uncomment this to switch) ---
# export VOLTA_HOME="$HOME/.volta"
# path_prepend "$VOLTA_HOME/bin"

# ════════════════════════════════════════════════════════════════
#  PYTHON — PYENV
#  pyenv init --path (shim injection) belongs in .bash_profile.
#  Only shell integration runs here to avoid PATH duplication.
# ════════════════════════════════════════════════════════════════
export PYENV_ROOT="$HOME/.pyenv"
path_prepend "$PYENV_ROOT/bin"
command -v pyenv &>/dev/null && eval "$(pyenv init -)"

# ════════════════════════════════════════════════════════════════
#  CUDA
# ════════════════════════════════════════════════════════════════
path_prepend "/opt/cuda/bin"
export LD_LIBRARY_PATH="/opt/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# ════════════════════════════════════════════════════════════════
#  PROMPT — git-aware, Gruvbox colours, exit-code indicator
# ════════════════════════════════════════════════════════════════
__git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
        || branch=$(git rev-parse --short HEAD 2>/dev/null) \
        || return
    local dirty=''
    git diff --quiet --ignore-submodules HEAD 2>/dev/null || dirty='*'
    printf ' (%s%s)' "$branch" "$dirty"
}

__set_ps1() {
    local code=$?
    local R='\[\033[0m\]'
    local B='\[\033[1m\]'
    local red='\[\033[38;2;251;73;52m\]'     # Gruvbox bright red   #fb4934
    local yel='\[\033[38;2;250;189;47m\]'    # Gruvbox yellow       #fabd2f
    local aqu='\[\033[38;2;142;192;124m\]'   # Gruvbox aqua         #8ec07c
    local gry='\[\033[38;2;168;153;132m\]'   # Gruvbox fg4          #a89984

    local err=''
    [[ $code -ne 0 ]] && err="${red}[${code}] "

    PS1="${err}${B}${yel}\u${R}${gry}@${aqu}\h${R} ${yel}\w${gry}$(__git_branch)${R} ${B}\$${R} "
}

PROMPT_COMMAND="__set_ps1; ${PROMPT_COMMAND:-}"

# ════════════════════════════════════════════════════════════════
#  COMPLETION
# ════════════════════════════════════════════════════════════════
if ! shopt -oq posix; then
    [[ -f /usr/share/bash-completion/bash_completion ]] \
        && source /usr/share/bash-completion/bash_completion \
        || [[ -f /etc/bash_completion ]] \
        && source /etc/bash_completion
fi

# ════════════════════════════════════════════════════════════════
#  FZF — fuzzy finder (install: pacman -S fzf)
# ════════════════════════════════════════════════════════════════
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash 2>/dev/null)" || {
        [[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
        [[ -f /usr/share/fzf/completion.bash   ]] && source /usr/share/fzf/completion.bash
    }
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
    command -v fd &>/dev/null \
        && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# ════════════════════════════════════════════════════════════════
#  ZOXIDE — smarter cd (install: pacman -S zoxide)
#  z foo     → jump to most frecent dir matching foo
#  zi foo    → interactive pick with fzf
# ════════════════════════════════════════════════════════════════
command -v zoxide &>/dev/null && eval "$(zoxide init bash)" && alias cd='z'

# ════════════════════════════════════════════════════════════════
#  ALIASES
# ════════════════════════════════════════════════════════════════

# ── Filesystem ─────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias lt='ls -lth'
alias lS='ls -lSh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# clear: wipe visible screen AND kitty scrollback buffer.
# Prevents ghost content in Quickshell overview window tiles.
# \033[2J = erase display  \033[3J = erase scrollback  \033[H = cursor home
alias clear='printf "\033[2J\033[3J\033[H"'

# ── Editor ─────────────────────────────────────────────────────
alias vi='nvim'
alias v='nvim'

# ── Git ────────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git log --oneline --graph --all --decorate'
alias glo='git log --oneline -20'
alias gd='git diff'
alias gds='git diff --staged'
alias gpom='git push -u origin main'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gst='git stash'
alias gstp='git stash pop'

# ── Docker ─────────────────────────────────────────────────────
alias dcub='docker compose up -d --build'
alias dcd='docker compose down'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dlogs='docker compose logs -f'
alias dprune='docker system prune -af'

# ── Node / TypeScript ──────────────────────────────────────────
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrs='npm run start'
alias nrt='npm run test'
alias ni='npm install'
alias tsc='npx tsc'

# ── Python ─────────────────────────────────────────────────────
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias activate='source .venv/bin/activate'

# ── System ─────────────────────────────────────────────────────
alias reload='source ~/.bashrc && echo "bashrc reloaded"'
alias path='echo "$PATH" | tr : "\n" | nl'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
alias df='df -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'
alias qs-reload='qs reload && echo "Quickshell reloaded."'

# ════════════════════════════════════════════════════════════════
#  FUNCTIONS
# ════════════════════════════════════════════════════════════════

# mkcd — mkdir + cd in one step
mkcd() { mkdir -p "$1" && cd "$1" || return 1; }

# up N — go up N directories  (up 3 == cd ../../..)
up() {
    local n="${1:-1}" t=""
    for (( i=0; i<n; i++ )); do t+="../"; done
    cd "$t" || return 1
}

# bak — copy file with timestamped .bak extension
bak() {
    [[ -f "$1" ]] || { echo "not a file: $1" >&2; return 1; }
    local dest="${1}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$1" "$dest" && echo "backed up → $dest"
}

# extract — universal archive extractor
extract() {
    [[ -f "$1" ]] || { echo "not a file: $1" >&2; return 1; }
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;; *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;; *.tar)     tar xf  "$1" ;;
        *.bz2)     bunzip2 "$1" ;; *.gz)      gunzip  "$1" ;;
        *.zip)     unzip   "$1" ;; *.7z)      7z x    "$1" ;;
        *.rar)     unrar x "$1" ;;
        *) echo "unsupported: $1" >&2; return 1 ;;
    esac
}

# serve — static file server in current directory
serve() {
    local port="${1:-8080}"
    echo "serving $(pwd) → http://localhost:${port}"
    python3 -m http.server "$port"
}

# tsinit — scaffold a TypeScript project
tsinit() {
    local name="${1:-.}"
    [[ "$name" != "." ]] && { mkdir -p "$name" && cd "$name" || return 1; }
    npm init -y
    npm install -D typescript @types/node ts-node
    npx tsc --init --target ES2020 --module commonjs --strict --outDir dist --rootDir src
    mkdir -p src
    printf 'console.log("hello typescript");\n' > src/index.ts
    printf 'node_modules/\ndist/\n' > .gitignore
    echo "TypeScript project ready in $(pwd)"
}

# devinfo — print all tool versions at a glance
devinfo() {
    printf "\n%-14s %s\n" "Java"       "$(java -version 2>&1 | head -1)"
    printf   "%-14s %s\n" "JAVA_HOME"  "$JAVA_HOME"
    printf   "%-14s %s\n" "Node"       "$(node  --version 2>/dev/null || echo 'not found')"
    printf   "%-14s %s\n" "npm"        "$(npm   --version 2>/dev/null || echo 'not found')"
    printf   "%-14s %s\n" "TypeScript" "$(npx tsc --version 2>/dev/null || echo 'not found')"
    printf   "%-14s %s\n" "Python"     "$(python3 --version 2>/dev/null)"
    printf   "%-14s %s\n" "pyenv"      "$(pyenv version-name 2>/dev/null || echo 'n/a')"
    printf   "%-14s %s\n" "Git"        "$(git --version)"
    printf   "%-14s %s\n" "Docker"     "$(docker --version 2>/dev/null || echo 'not found')"
    printf   "%-14s %s\n" "nvim"       "$(nvim --version 2>/dev/null | head -1)"
    echo ""
}

nodev()   { nvm use "$1" && node --version; }
whichpy() { echo "$(which python3)  $(python3 --version)  pyenv:$(pyenv version-name 2>/dev/null)"; }
javainfo(){ echo "$(java -version 2>&1 | head -1)  JAVA_HOME=$JAVA_HOME"; }
showpath(){ echo "$PATH" | tr ':' '\n' | nl; }