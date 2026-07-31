set shell := ["bash", "-c"]

assets := "/usr/share/bazzite-htpc"

# Full setup — idempotent, safe to rerun after image updates
setup: check-not-root setup-nas install-flatpaks setup-jellyfin setup-navidrome setup-decky

# Guard against running as root
check-not-root:
    #!/usr/bin/env bash
    if [ "$EUID" -eq 0 ]; then
        echo "Error: do not run setup as root — use your normal user account"
        exit 1
    fi

# Write NAS credentials and enable automount
# Skips credential prompt if /etc/samba/nas-credentials already exists
setup-nas:
    #!/usr/bin/env bash
    if [ ! -f /etc/samba/nas-credentials ]; then
        read -p "NAS username: " nas_user
        read -s -p "NAS password: " nas_pass
        echo
        sudo mkdir -p /etc/samba
        nas_user="${nas_user//$'\r'/}"
        nas_pass="${nas_pass//$'\r'/}"
        printf "username=%s\npassword=%s\n" "$nas_user" "$nas_pass" \
            | sudo tee /etc/samba/nas-credentials > /dev/null
        sudo chmod 600 /etc/samba/nas-credentials
        echo "NAS credentials written."
    else
        echo "NAS credentials already exist, skipping."
    fi
    sudo systemctl daemon-reload
    sudo systemctl enable --now var-mnt-nas.automount

# Install user Flatpaks — skips already-installed apps
install-flatpaks:
    xargs flatpak install --system --noninteractive --or-update flathub < {{assets}}/flatpaks.txt

# Deploy Jellyfin container unit — restarts service only if unit file changed
setup-jellyfin:
    #!/usr/bin/env bash
    loginctl enable-linger "$USER"
    mkdir -p ~/.config/jellyfin/{config,cache}
    mkdir -p ~/.config/containers/systemd
    src="{{assets}}/jellyfin.container"
    dest="$HOME/.config/containers/systemd/jellyfin.container"
    if ! cmp -s "$src" "$dest"; then
        cp "$src" "$dest"
        systemctl --user daemon-reload
        systemctl --user restart jellyfin
        echo "Jellyfin container unit updated and restarted."
    else
        echo "Jellyfin container unit unchanged, skipping restart."
    fi
    echo "Jellyfin running at http://localhost:8096"

# Deploy Navidrome container unit — restarts service only if unit file changed
# Music is read from /var/mnt/nas/Music — adjust path if your NAS layout differs
setup-navidrome:
    #!/usr/bin/env bash
    loginctl enable-linger "$USER"
    mkdir -p ~/.config/navidrome/data
    mkdir -p ~/.config/containers/systemd
    src="{{assets}}/navidrome.container"
    dest="$HOME/.config/containers/systemd/navidrome.container"
    if ! cmp -s "$src" "$dest"; then
        cp "$src" "$dest"
        systemctl --user daemon-reload
        systemctl --user restart navidrome
        echo "Navidrome container unit updated and restarted."
    else
        echo "Navidrome container unit unchanged, skipping restart."
    fi
    echo "Navidrome running at http://localhost:4533"

# Install Node.js via brew and Claude Code CLI
setup-claude-code:
    #!/usr/bin/env bash
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    brew install node
    npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed. Run: claude"
