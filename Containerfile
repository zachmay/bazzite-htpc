ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG TAG="stable"

FROM ${BASE_IMAGE}:${TAG}

# Copy system config files (mount units, tmpfiles, wayland sessions, quadlets)
COPY config/files/ /

# Copy setup assets
COPY justfile /usr/share/ublue-os/just/60-custom.just
COPY flatpaks.txt /usr/share/bazzite-htpc/flatpaks.txt

# Enable NAS automount, NetworkManager, and configure Flathub system remote
# Quadlet units need no enable — the generator acts on their [Install] section
RUN systemctl enable var-mnt-nas.automount \
    && systemctl enable NetworkManager \
    && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
    && ostree container commit

RUN ostree container commit
