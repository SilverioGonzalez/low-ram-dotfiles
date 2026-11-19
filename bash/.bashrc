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

# Lightweight robbyrussell-inspired prompt (arrow, directory, git branch + dirty indicator)
__git_prompt() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return
  local dirty=""
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    dirty=" \033[1;33m✗\033[0m"
  fi
  printf " \033[1;34mgit:(\033[0;31m%s\033[1;34m)\033[0m%b" "$branch" "$dirty"
}

__set_prompt() {
  local exit_code=$?
  local arrow_color="\033[1;32m"
  [ "$exit_code" -ne 0 ] && arrow_color="\033[1;31m"
  local dir_name
  if [ "$PWD" = "$HOME" ]; then
    dir_name="~"
  else
    dir_name="${PWD##*/}"
  fi
  PS1="\[${arrow_color}\]➜\[\033[0m\] \[\033[1;36m\]${dir_name}\[\033[0m\]\$(__git_prompt) "
}

PROMPT_COMMAND="__set_prompt"

# Render images in fzf natively using ghostty's terminal graphics protocol
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
