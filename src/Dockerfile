FROM ubuntu:22.04

LABEL maintainer="Anthony Izzo <izzo.anthony@gmail.com>"
LABEL description="DockFuse - Docker container for mounting S3 buckets using s3fs-fuse"
LABEL version="1.1.0"

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
    timeout \
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

# Create mount directory
RUN mkdir -p /mnt/s3bucket

# Copy scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Create cache directory with appropriate permissions
RUN mkdir -p /tmp/s3fs_cache && chmod 777 /tmp/s3fs_cache

# Set environment variables
ENV MOUNT_POINT=/mnt/s3bucket \
    DEBUG=0 \
    S3_PATH=/ \
    HEALTH_CHECK_TIMEOUT=5 \
    HEALTH_CHECK_WRITE_TEST=0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["daemon"]