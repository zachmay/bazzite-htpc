ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG TAG="stable"

FROM ${BASE_IMAGE}:${TAG}

# Install system packages
RUN rpm-ostree install just \
    && ostree container commit

# Copy system config files (mount units, etc.) and setup assets
COPY config/files/ /
COPY justfile /usr/share/bazzite-htpc/justfile
COPY config/jellyfin.container /usr/share/bazzite-htpc/jellyfin.container
COPY flatpaks.txt /usr/share/bazzite-htpc/flatpaks.txt

# Enable NAS automount and create mount point
RUN mkdir -p /var/mnt/nas \
    && systemctl enable var-mnt-nas.automount \
    && ostree container commit

RUN ostree container commit
