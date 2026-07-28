set shell := ["bash", "-c"]

assets := "/usr/share/bazzite-htpc"

# Full setup — idempotent, safe to rerun after image updates
setup: setup-nas install-flatpaks setup-jellyfin

# Write NAS credentials and enable automount
# Skips credential prompt if /etc/samba/nas-credentials already exists
setup-nas:
    #!/usr/bin/env bash
    if [ ! -f /etc/samba/nas-credentials ]; then
        read -p "NAS username: " nas_user
        read -s -p "NAS password: " nas_pass
        echo
        sudo mkdir -p /etc/samba
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
    xargs flatpak install --noninteractive --or-update flathub < {{assets}}/flatpaks.txt

# Deploy Jellyfin container unit — restarts service only if unit file changed
setup-jellyfin:
    #!/usr/bin/env bash
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
    systemctl --user enable jellyfin
    echo "Jellyfin running at http://localhost:8096"
