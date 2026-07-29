ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG TAG="stable"

FROM ${BASE_IMAGE}:${TAG}

# Copy system config files (mount units, tmpfiles, wayland sessions)
COPY config/files/ /

# Copy setup assets
COPY justfile /usr/share/ublue-os/just/60-htpc.just
COPY config/jellyfin.container /usr/share/bazzite-htpc/jellyfin.container
COPY config/navidrome.container /usr/share/bazzite-htpc/navidrome.container
COPY flatpaks.txt /usr/share/bazzite-htpc/flatpaks.txt

# Enable NAS automount
RUN systemctl enable var-mnt-nas.automount \
    && ostree container commit

RUN ostree container commit
