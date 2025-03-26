FROM ubuntu:22.04

LABEL maintainer="Anthony Izzo <izzo.anthony@gmail.com>"
LABEL description="DockFuse - Docker container for mounting S3 buckets using s3fs-fuse"
LABEL version="1.1.0"

# Install tini for proper init and signal handling
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

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

# Set environment variables
ENV MOUNT_POINT=/mnt/s3bucket \
    DEBUG=0 \
    S3_PATH=/ \
    HEALTH_CHECK_TIMEOUT=5 \
    HEALTH_CHECK_WRITE_TEST=0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]

# Switch to non-root user
USER s3fs

# Use tini as init and then our entrypoint
CMD ["/tini", "--", "/usr/local/bin/entrypoint.sh", "daemon"]