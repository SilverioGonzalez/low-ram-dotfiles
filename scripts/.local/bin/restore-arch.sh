#!/usr/bin/env bash
set -euo pipefail

# Determine whether we are running as root or a standard user
if [ "$(id -u)" -eq 0 ]; then
    PRIV=""
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Error: 'sudo' is not installed. Run 'su -c \"pacman -S --needed sudo\"' as root first, then re-run this script."
        exit 1
    fi
    PRIV="sudo"
fi

echo "=== 1. Installing Missing Arch System Packages, Sudo, Stow, NetworkManager, Reflector, UFW & Timeshift ==="
$PRIV pacman -Syu --needed \
    sudo \
    base-devel \
    git \
    stow \
    networkmanager \
    reflector \
    ufw \
    timeshift \
    cronie \
    bluez \
    bluez-utils \
    bluetui \
    man-db \
    man-pages \
    texinfo \
    curl \
    wget \
    openssh \
    rsync \
    bash-completion \
    less \
    zip \
    unzip \
    btop \
    htop \
    jolt \
    fastfetch \
    brightnessctl \
    pipewire \
    pipewire-pulse \
    wireplumber \
    wiremix

echo "=== 2. Enabling NetworkManager, Bluetooth, Cronie & Configuring Reflector ==="
$PRIV systemctl enable --now NetworkManager.service
$PRIV systemctl enable --now bluetooth.service
$PRIV systemctl enable --now cronie.service

if [ ! -f /etc/xdg/reflector/reflector.conf ]; then
    $PRIV mkdir -p /etc/xdg/reflector
    cat << 'EOF' | $PRIV tee /etc/xdg/reflector/reflector.conf > /dev/null
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 15
--age 12
--sort rate
EOF
    $PRIV systemctl enable --now reflector.timer
    echo "Updating Pacman mirrorlist with Reflector..."
    $PRIV reflector --protocol https --latest 15 --age 12 --sort rate --save /etc/pacman.d/mirrorlist
else
    $PRIV systemctl enable --now reflector.timer
    echo "Reflector is already configured; skipping manual mirror refresh."
fi

echo "=== 3. Creating Pacman Pre-Upgrade Timeshift Hook (Keep Last 5 Snapshots) ==="
if [ ! -f /usr/local/bin/timeshift-pacman-hook ]; then
    cat << 'EOF' | $PRIV tee /usr/local/bin/timeshift-pacman-hook > /dev/null
#!/usr/bin/env bash
set -euo pipefail

MAX_SNAPSHOTS=5
COMMENT="Before Pacman upgrade"

# Create the new pre-upgrade snapshot
/usr/bin/timeshift --create --comments "$COMMENT" --tags O --scripted

# Find all pre-upgrade snapshots sorted oldest-first and prune beyond MAX_SNAPSHOTS
mapfile -t SNAPSHOTS < <(/usr/bin/timeshift --list 2>/dev/null | grep "$COMMENT" | awk '{print $3}' | sort)

COUNT=${#SNAPSHOTS[@]}
if [ "$COUNT" -gt "$MAX_SNAPSHOTS" ]; then
    TO_DELETE=$((COUNT - MAX_SNAPSHOTS))
    for ((i = 0; i < TO_DELETE; i++)); do
        echo "Pruning old pre-upgrade snapshot: ${SNAPSHOTS[$i]}"
        /usr/bin/timeshift --delete --snapshot "${SNAPSHOTS[$i]}" --scripted
    done
fi
EOF
    $PRIV chmod +x /usr/local/bin/timeshift-pacman-hook
fi

if [ ! -f /etc/pacman.d/hooks/50-timeshift.hook ]; then
    $PRIV mkdir -p /etc/pacman.d/hooks
    cat << 'EOF' | $PRIV tee /etc/pacman.d/hooks/50-timeshift.hook > /dev/null
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Creating pre-upgrade Timeshift snapshot (keeping last 5)...
When = PreTransaction
Exec = /usr/local/bin/timeshift-pacman-hook
AbortOnFail
EOF
fi

echo "=== 4. Configuring UFW Firewall (Sane Defaults & LAN-Only SSH Rate Limiting) ==="
$PRIV ufw default deny incoming >/dev/null
$PRIV ufw default allow outgoing >/dev/null
if ! $PRIV ufw status | grep -q "192.168.0.0/16"; then
    $PRIV ufw limit from 192.168.0.0/16 to any port 22 proto tcp
    $PRIV ufw limit from 10.0.0.0/8 to any port 22 proto tcp
    $PRIV ufw limit from 172.16.0.0/12 to any port 22 proto tcp
fi
$PRIV ufw --force enable >/dev/null
$PRIV systemctl enable --now ufw.service

echo "=== 5. Hardening & Enabling OpenSSH (Port 22, Key-Only, No Root) ==="
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

if [ ! -f /etc/ssh/sshd_config.d/10-hardening.conf ]; then
    $PRIV mkdir -p /etc/ssh/sshd_config.d
    cat << 'EOF' | $PRIV tee /etc/ssh/sshd_config.d/10-hardening.conf > /dev/null
Port 22
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
EOF
    $PRIV sshd -t
fi
$PRIV systemctl enable --now sshd.service

echo "=== 6. Installing Missing Display Manager (Ly) & Hyprland Ecosystem ==="
$PRIV pacman -S --needed \
    ly \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    hyprpolkitagent \
    hyprpaper \
    hyprlock \
    hypridle \
    hyprpicker \
    hyprsunset \
    hyprshutdown \
    uwsm

# Enable Ly on tty2 (standard ArchWiki setup)
$PRIV systemctl disable getty@tty2.service 2>/dev/null || true
$PRIV systemctl enable ly@tty2.service


set -euo pipefail

# Determine whether we are running as root or a standard user
if [ "$(id -u)" -eq 0 ]; then
    PRIV=""
    echo "Running as root. Note: AUR packages (yay, pacsea-bin, surge) must be installed as a non-root user."
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Error: 'sudo' is not installed. Run 'su -c \"pacman -S --needed sudo\"' as root first, then re-run this script."
        exit 1
    fi
    PRIV="sudo"
fi

echo "=== 7. Installing Missing Ghostty, Waybar, Qt/GTK Dark Mode & Companion Tools ==="
$PRIV pacman -S --needed \
    ghostty \
    waybar \
    mako \
    rofi-wayland \
    grim \
    slurp \
    wl-clipboard \
    qt5-wayland \
    qt6-wayland \
    qt5ct \
    qt6ct \
    breeze \
    gnome-themes-extra \
    ttf-jetbrains-mono-nerd

echo "=== 8. Installing Missing Neovim, Tmux & Search Utilities ==="
$PRIV pacman -S --needed \
    neovim \
    tmux \
    ripgrep \
    fd

echo "=== 9. Installing Missing Zoxide, FZF, Yazi & Preview Dependencies ==="
$PRIV pacman -S --needed \
    zoxide \
    fzf \
    yazi \
    ffmpeg \
    7zip \
    jq \
    poppler \
    resvg \
    imagemagick \
    chafa

echo "=== 10. Installing Yay & Missing AUR TUI Apps (Pacsea & Surge Download Manager) ==="
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v yay >/dev/null 2>&1; then
        echo "Bootstrapping yay-bin from the AUR..."
        TMP_YAY=$(mktemp -d)
        git clone https://archlinux.org "$TMP_YAY/yay-bin"
        (cd "$TMP_YAY/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$TMP_YAY"
    else
        echo "yay is already installed."
    fi

    yay -S --needed --noconfirm pacsea-bin surge
else
    echo "Skipping yay/AUR installs because script is running as root. Re-run as your normal user to install pacsea-bin and surge."
fi

echo "=== 11. Configuring Ghostty (If Not Already Present) ==="
mkdir -p ~/.config/ghostty
if [ ! -f ~/.config/ghostty/config ]; then
    cat << 'EOF' > ~/.config/ghostty/config
font-family = JetBrainsMono Nerd Font
font-size = 12
theme = Catppuccin Mocha
shell-integration-features = sudo
EOF
    echo "Created starter ~/.config/ghostty/config"
else
    echo "~/.config/ghostty/config already exists; keeping existing config."
fi

echo "=== 12. Configuring Tmux (If Not Already Present) ==="
if [ ! -f ~/.tmux.conf ]; then
    cat << 'EOF' > ~/.tmux.conf
set -g default-terminal "tmux-256color"
set -as terminal-features ",xterm-ghostty:RGB"
set -g mouse on
set -sg escape-time 10
set -g base-index 1
setw -g pane-base-index 1
EOF
    echo "Created starter ~/.tmux.conf"
else
    echo "~/.tmux.conf already exists; keeping existing config."
fi


#!/usr/bin/env bash
set -euo pipefail

# Optional: Set your GitHub dotfiles URL below to clone and symlink via Stow on restore
#DOTFILES_DIR="$HOME/dotfiles"
#DOTFILES_REPO=""

echo "=== 13. Configuring Yazi Theme (If Not Already Present) ==="
mkdir -p ~/.config/yazi
if ! ya pkg list 2>/dev/null | grep -q "catppuccin-mocha"; then
    ya pkg add yazi-rs/flavors:catppuccin-mocha
fi

if [ ! -f ~/.config/yazi/theme.toml ]; then
    cat << 'EOF' > ~/.config/yazi/theme.toml
[flavor]
dark = "catppuccin-mocha"
EOF
    echo "Created ~/.config/yazi/theme.toml"
else
    echo "~/.config/yazi/theme.toml already exists; keeping existing config."
fi

echo "=== 14. Configuring Global Dark Mode (GTK3/GTK4, XDG Portal & Qt5/Qt6) ==="
if command -v gsettings >/dev/null 2>&1; then
    dbus-run-session gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    dbus-run-session gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
fi

mkdir -p ~/.config/xdg-desktop-portal
if [ ! -f ~/.config/xdg-desktop-portal/portals.conf ]; then
    cat << 'EOF' > ~/.config/xdg-desktop-portal/portals.conf
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Settings=gtk
EOF
fi

mkdir -p ~/.config/gtk-3.0
if [ ! -f ~/.config/gtk-3.0/settings.ini ]; then
    cat << 'EOF' > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=true
EOF
fi

mkdir -p ~/.config/qt5ct ~/.config/qt6ct
if [ ! -f ~/.config/qt5ct/qt5ct.conf ]; then
    cat << 'EOF' > ~/.config/qt5ct/qt5ct.conf
[Appearance]
color_scheme_path=/usr/share/color-schemes/BreezeDark.colors
custom_palette=true
style=Breeze
EOF
fi

if [ ! -f ~/.config/qt6ct/qt6ct.conf ]; then
    cat << 'EOF' > ~/.config/qt6ct/qt6ct.conf
[Appearance]
color_scheme_path=/usr/share/color-schemes/BreezeDark.colors
custom_palette=true
style=Breeze
EOF
fi

echo "=== 15. Configuring Shell Integrations (FZF, Zoxide & Yazi 'y' Wrapper) ==="
CURRENT_SHELL=$(basename "$SHELL")

configure_bash() {
    local rc="$HOME/.bashrc"
    touch "$rc"
    if ! grep -q "zoxide init bash" "$rc"; then
        cat << 'EOF' >> "$rc"

# --- FZF, Zoxide & Yazi Integrations ---
eval "$(fzf --bash)"
eval "$(zoxide init bash)"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
EOF
        echo "Added integrations to ~/.bashrc"
    else
        echo "Shell integrations are already present in ~/.bashrc"
    fi
}

configure_zsh() {
    local rc="$HOME/.zshrc"
    touch "$rc"
    if ! grep -q "zoxide init zsh" "$rc"; then
        cat << 'EOF' >> "$rc"

# --- FZF, Zoxide & Yazi Integrations ---
source <(fzf --zsh)
eval "$(zoxide init zsh)"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
EOF
        echo "Added integrations to ~/.zshrc"
    else
        echo "Shell integrations are already present in ~/.zshrc"
    fi
}

if [ "$CURRENT_SHELL" = "zsh" ]; then
    configure_zsh
elif [ "$CURRENT_SHELL" = "bash" ]; then
    configure_bash
else
    echo "Detected shell '$CURRENT_SHELL'. Please add fzf/zoxide hooks manually if using Fish or another shell."
fi

echo "=== 16. Creating Custom User Scripts (~/.local/bin/launch_app, add_app, select_wallpaper & power_menu) ==="
mkdir -p ~/.local/bin ~/.local/share/applications ~/wallpaper

if [ ! -f ~/.local/bin/launch_app ] || grep -q "awk -F=" ~/.local/bin/launch_app; then
    cat << 'EOF' > ~/.local/bin/launch_app
#!/usr/bin/env bash

# Find all .desktop files, extract Name and Exec lines, and pipe into fzf
selected=$(grep -hE "^(Name|Exec)=" /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null | \
awk '
    /^Name=/ { sub(/^Name=/, ""); name=$0 }
    /^Exec=/ && name {
        sub(/^Exec=/, "")
        # Strip desktop field codes like %u, %U, %f, %F
        gsub(/ %[uUfFdDnNickvm]/, "")
        print name "\t" $0
        name=""
    }
' | sort -u -t$'\t' -k1,1 | fzf --delimiter=$'\t' --with-nth=1 --prompt="Launch: " --layout=reverse --border)

# Exit cleanly if Escape/Ctrl+C was pressed
[ -z "$selected" ] && exit 0

# Extract the command and launch it detached via Hyprland
cmd=$(echo "$selected" | cut -f2-)
hyprctl dispatch exec "$cmd" >/dev/null 2>&1
EOF
    chmod +x ~/.local/bin/launch_app
    echo "Installed patched ~/.local/bin/launch_app"
else
    echo "~/.local/bin/launch_app is already up to date; keeping existing script."
fi

if [ ! -f ~/.local/bin/add_app ]; then
    cat << 'EOF' > ~/.local/bin/add_app
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/.local/share/applications"
mkdir -p "$APP_DIR"

# 1. Select the type of entry using fzf
type=$(printf "GUI App\nTUI App (Ghostty)\nWeb App (URL)" | fzf --prompt="App Type: " --layout=reverse --border --height=40%)
[ -z "$type" ] && exit 0

# 2. Prompt for the display name
read -rp "App Name (e.g., Boot.dev): " name
[ -z "$name" ] && { echo "Name cannot be empty."; exit 1; }

# 3. Prompt for the command or web address
if [ "$type" = "Web App (URL)" ]; then
    read -rp "Web Address (e.g., https://boot.dev): " target
    [ -z "$target" ] && { echo "URL cannot be empty."; exit 1; }
    # Prepend https:// automatically if omitted
    [[ "$target" != http://* && "$target" != https://* ]] && target="https://$target"
    exec_cmd="xdg-open $target"
elif [ "$type" = "TUI App (Ghostty)" ]; then
    read -rp "TUI Command (e.g., wiremix): " target
    [ -z "$target" ] && { echo "Command cannot be empty."; exit 1; }
    exec_cmd="ghostty -e $target"
else
    read -rp "Command or Path (e.g., /usr/bin/app): " target
    [ -z "$target" ] && { echo "Command cannot be empty."; exit 1; }
    exec_cmd="$target"
fi

# Generate a clean, safe filename (e.g., "Boot.dev" -> "custom-boot-dev.desktop")
slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g')
desktop_file="$APP_DIR/custom-${slug}.desktop"

cat << DESKTOP > "$desktop_file"
[Desktop Entry]
Type=Application
Name=$name
Exec=$exec_cmd
Terminal=false
Categories=Utility;
DESKTOP

echo "Added '$name' -> $desktop_file"
EOF
    chmod +x ~/.local/bin/add_app
    echo "Created ~/.local/bin/add_app"
else
    echo "~/.local/bin/add_app already exists; keeping existing script."
fi

if [ ! -f ~/.local/bin/select_wallpaper ]; then
    cat << 'EOF' > ~/.local/bin/select_wallpaper
#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Find image files in ~/wallpaper/ and preview them with chafa in fzf
selected=$(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | \
    sed "s|^$WALLPAPER_DIR/||" | \
    sort | \
    fzf --prompt="Wallpaper: " --layout=reverse --border \
        --preview "chafa -s \${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES} '$WALLPAPER_DIR/{}'")

# Exit cleanly if Escape or Ctrl+C was pressed
[ -z "$selected" ] && exit 0

FULL_PATH="$WALLPAPER_DIR/$selected"

# Write updated hyprpaper.conf matching your working 0.8+ syntax
cat << CONF > "$HYPRPAPER_CONF"
# Generated by select_wallpaper
ipc = true
splash = false

wallpaper {
    monitor = 
    path = $FULL_PATH
    fit_mode = cover
}
CONF

# Start hyprpaper if not already running, then apply the wallpaper via IPC
if ! pgrep -x hyprpaper >/dev/null; then
    hyprctl dispatch exec hyprpaper >/dev/null 2>&1
    sleep 0.5
fi

hyprctl hyprpaper wallpaper ",$FULL_PATH,cover" >/dev/null 2>&1
EOF
    chmod +x ~/.local/bin/select_wallpaper
    echo "Created ~/.local/bin/select_wallpaper"
else
    echo "~/.local/bin/select_wallpaper already exists; keeping existing script."
fi

if [ ! -f ~/.local/bin/power_menu ]; then
    cat << 'EOF' > ~/.local/bin/power_menu
#!/usr/bin/env bash

# Define the menu options
options="Lock\nLogout\nSuspend\nReboot\nShutdown"

# Pipe options into fzf
selected=$(echo -e "$options" | fzf --prompt="Power: " --layout=reverse --border --height=100%)

# Exit cleanly if Escape or Ctrl+C was pressed
[ -z "$selected" ] && exit 0

# Execute the chosen action
case "$selected" in
    "Lock")
        pidof hyprlock || hyprlock
        ;;
    "Logout")
        hyprctl dispatch exit
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
esac
EOF
    chmod +x ~/.local/bin/power_menu
    echo "Created ~/.local/bin/power_menu"
else
    echo "~/.local/bin/power_menu already exists; keeping existing script."
fi

echo "=== 17. Restoring Dotfiles via GNU Stow (If DOTFILES_REPO Is Set) ==="
if [ -n "$DOTFILES_REPO" ]; then
    if [ ! -d "$DOTFILES_DIR" ]; then
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        git -C "$DOTFILES_DIR" pull --ff-only || true
    fi
    (cd "$DOTFILES_DIR" && stow --no-folding -t "$HOME" */ 2>/dev/null || echo "Note: Some dotfiles already exist; existing files were kept protected.")
else
    echo "DOTFILES_REPO is empty; skipping automated Stow symlink step."
fi

echo "=== Part 3 (Sections 13-17) & Full System Restore Complete! ==="
echo "Hyprland Modules Reminder: Ensure your modules include '\$terminal = ghostty', 'exec-once = waybar', and 'env = QT_QPA_PLATFORMTHEME,qt6ct'."
echo "TUI Quick Commands: 'wiremix' (Audio) | 'bluetui' (Bluetooth) | 'nmtui' (Wi-Fi/Network) | 'btop' / 'htop' (System) | 'jolt' (Battery) | 'fastfetch' (Info) | 'pacsea' (Packages) | 'surge' (Downloads)"
