ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG TAG="stable"

FROM ${BASE_IMAGE}:${TAG}

# Install system packages
RUN rpm-ostree install just \
    && ostree container commit

# Copy system config files (mount units, etc.)
COPY config/files/ /

# Enable NAS automount and create mount point
RUN mkdir -p /var/mnt/nas \
    && systemctl enable var-mnt-nas.automount \
    && ostree container commit

RUN ostree container commit
