FROM ubuntu:22.04

LABEL maintainer="Anthony Izzo <izzo.anthony@gmail.com>"
LABEL description="DockFuse - Docker container for mounting S3 buckets using s3fs-fuse"
LABEL version="1.1.0"

# Install s6 for proper init and signal handling
RUN apt-get update && apt-get install -y \
    xz-utils \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install s6 overlay
ENV S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

# Set s6 init as entrypoint
ENTRYPOINT ["/init"]

# Install dependencies
RUN apt-get update && apt-get install -y \
    automake \
    autotools-dev \
    fuse \
    g++ \
    git \
    libcurl4-openssl-dev \
    libfuse-dev \
    libssl-dev \
    libxml2-dev \
    make \
    pkg-config \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Clone and install latest s3fs
RUN cd /tmp \
    && git clone https://github.com/s3fs-fuse/s3fs-fuse.git \
    && cd s3fs-fuse \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /tmp/s3fs-fuse

# Create non-root user for s3fs
RUN groupadd -g 1000 s3fs && \
    useradd -u 1000 -g s3fs -m s3fs

# Create mount directory with proper permissions
RUN mkdir -p /mnt/s3bucket && \
    chown s3fs:s3fs /mnt/s3bucket

# Create cache directory with appropriate permissions
RUN mkdir -p /tmp/s3fs_cache && \
    chown s3fs:s3fs /tmp/s3fs_cache && \
    chmod 777 /tmp/s3fs_cache

# Copy scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

# Make scripts executable and set ownership
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh && \
    chown s3fs:s3fs /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Set up s6 service directories
RUN mkdir -p /etc/s6-overlay/s6-rc.d/s3fs \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/s3fs \
    && mkdir -p /etc/s6-overlay/s6-rc.d/s3fs/dependencies.d

# Copy s6 service files
COPY s6-service/run /etc/s6-overlay/s6-rc.d/s3fs/run
COPY s6-service/finish /etc/s6-overlay/s6-rc.d/s3fs/finish
RUN chmod +x /etc/s6-overlay/s6-rc.d/s3fs/run /etc/s6-overlay/s6-rc.d/s3fs/finish

# Set environment variables
ENV MOUNT_POINT=/mnt/s3bucket \
    DEBUG=0 \
    S3_PATH=/ \
    HEALTH_CHECK_TIMEOUT=5 \
    HEALTH_CHECK_WRITE_TEST=0 \
    S6_KEEP_ENV=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]

# Switch to non-root user
USER s3fs

# Use s6 and our entrypoint script
CMD ["/usr/local/bin/entrypoint.sh", "daemon"]