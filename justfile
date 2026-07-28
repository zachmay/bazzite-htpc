set shell := ["bash", "-c"]

# Full first-boot setup
setup: setup-nas install-flatpaks setup-jellyfin

# Mount NAS — prompts for credentials, writes /etc/samba/nas-credentials
setup-nas:
    #!/usr/bin/env bash
    read -p "NAS username: " nas_user
    read -s -p "NAS password: " nas_pass
    echo
    sudo mkdir -p /etc/samba
    printf "username=%s\npassword=%s\n" "$nas_user" "$nas_pass" \
        | sudo tee /etc/samba/nas-credentials > /dev/null
    sudo chmod 600 /etc/samba/nas-credentials
    sudo systemctl daemon-reload
    sudo systemctl enable --now var-mnt-nas.automount
    echo "NAS mount configured. Test with: ls /var/mnt/nas"

# Install user Flatpaks
install-flatpaks:
    xargs flatpak install --noninteractive flathub < flatpaks.txt

# Start Jellyfin Media Server container
setup-jellyfin:
    mkdir -p ~/.config/jellyfin/{config,cache}
    mkdir -p ~/.config/containers/systemd
    cp config/jellyfin.container ~/.config/containers/systemd/jellyfin.container
    systemctl --user daemon-reload
    systemctl --user enable --now jellyfin
    echo "Jellyfin running at http://localhost:8096"
