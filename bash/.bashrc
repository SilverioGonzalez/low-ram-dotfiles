# Enable the subsequent settings only in interactive sessions
case $- in
    *i*) ;;
    *) return ;;
esac

# Global Terminal & Workspace Environment
export TERMINAL="ghostty"
export EDITOR="nvim"
export VISUAL="nvim"

# Load fastfetch on start
fastfetch

# Rendering images in fzf natively using ghostty's terminal graphics protocol
fzf-image-preview() {
    fzf --preview='
        mimetype=$(file --mime-type -b {})
        if [[ "$mimetype" =~ ^image/ ]]; then
            # Clear previous image and draw the new one directly using ghostty/kitty shared graphics protocols
            ghostty +kitten icat --clear --silent --stdin=no --transfer-mode=memory --place="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" {} > /dev/tty
        else
            # Fallback for text or other files
            bat --color=always {} 2>/dev/null || cat {}
        fi
    '
}

# Path to your oh-my-bash installation.
export OSH=$HOME/.oh-my-bash

# Oh my bash themes
# OSH_THEME="font"
OSH_THEME="robbyrussell"
# OSH_THEME="nekonight_moon"

# Uncomment the following line to use case-sensitive completion.
# OMB_CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# OMB_HYPHEN_SENSITIVE="false"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_OSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you don't want the repository to be considered dirty
# if there are untracked files.
# SCM_GIT_DISABLE_UNTRACKED_DIRTY="true"

# Uncomment the following line if you want to completely ignore the presence
# of untracked files in the repository.
# SCM_GIT_IGNORE_UNTRACKED="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output. One of the following values can
# be used to specify the timestamp format.
# * 'mm/dd/yyyy'     # mm/dd/yyyy + time
# * 'dd.mm.yyyy'     # dd.mm.yyyy + time
# * 'yyyy-mm-dd'     # yyyy-mm-dd + time
# * '[mm/dd/yyyy]'   # [mm/dd/yyyy] + [time] with colors
# * '[dd.mm.yyyy]'   # [dd.mm.yyyy] + [time] with colors
# * '[yyyy-mm-dd]'   # [yyyy-mm-dd] + [time] with colors
# If not set, the default value is 'yyyy-mm-dd'.
# HIST_STAMPS='yyyy-mm-dd'

# Uncomment the following line if you do not want OMB to overwrite the existing
# aliases by the default OMB aliases defined in lib/*.sh
# OMB_DEFAULT_ALIASES="check"

# Would you like to use another custom folder than $OSH/custom?
# OSH_CUSTOM=/path/to/new-custom-folder

# To disable the uses of "sudo" by oh-my-bash, please set "false" to
# this variable. The default behavior for the empty value is "true".
OMB_USE_SUDO=true

# To enable/disable display of Python virtualenv and condaenv
# OMB_PROMPT_SHOW_PYTHON_VENV=true  # enable
# OMB_PROMPT_SHOW_PYTHON_VENV=false # disable

# To enable/disable Spack environment information
# OMB_PROMPT_SHOW_SPACK_ENV=true  # enable
# OMB_PROMPT_SHOW_SPACK_ENV=false # disable

# Which completions would you like to load? (completions can be found in ~/.oh-my-bash/completions/*)
# Custom completions may be added to ~/.oh-my-bash/custom/completions/
# Example format: completions=(ssh git bundler gem pip pip3)
# Add wisely, as too many completions slow down shell startup.
# completions=(
#     git
#     composer
#     ssh
# )

# Which aliases would you like to load? (aliases can be found in ~/.oh-my-bash/aliases/*)
# Custom aliases may be added to ~/.oh-my-bash/custom/aliases/
# Example format: aliases=(vagrant composer git-avh)
# Add wisely, as too many aliases slow down shell startup.
aliases=(
    general
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(
#     git
#     bashmarks
# )

# Which plugins would you like to conditionally load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format:
# if [ "$DISPLAY" ] || [ "$SSH" ]; then
#     plugins+=(tmux-autoattach)
# fi

# If you want to reduce the initialization cost of the "tput" command to
# initialize color escape sequences, you can uncomment the following setting.
# This disables the use of the "tput" command, and the escape sequences are
# initialized to be the ANSI version:
# OMB_TERM_USE_TPUT=no

BASH_CACHE_DIR=$HOME/.cache/oh-my-bash
if [[ ! -d $BASH_CACHE_DIR ]]; then
    mkdir -p "$BASH_CACHE_DIR"
fi

source "$OSH"/oh-my-bash.sh
eval "$(fzf --bash)"

# Fuzzy find a file and open it with your default editor
fff() {
    local file
    file=$(find . -type f | fzf)
    [ -n "$file" ] && "${EDITOR:-nvim}" "$file"
}

# Fuzzy find a directory and cd into it
ffd() {
    local dir
    dir=$(find . -type d | fzf)
    [ -n "$dir" ] && cd "$dir"
}

eval "$(zoxide init bash)"
export PATH="$HOME/.local/bin:$PATH"


