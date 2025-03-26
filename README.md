# DockFuse

[![Docker Hub](https://img.shields.io/docker/pulls/amizzo/dockfuse.svg)](https://hub.docker.com/r/amizzo/dockfuse)

DockFuse is a Docker-based solution for mounting S3 buckets as local volumes using s3fs-fuse.

## Table of Contents
- [Features](#features)
- [Quick Start](#quick-start)
- [Docker Compose Setup](#docker-compose-setup)
- [Mounting Options](#mounting-options)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [Health Monitoring](#health-monitoring)
- [Troubleshooting](#troubleshooting)
- [Advanced Use Cases](#advanced-use-cases)
- [Continuous Integration & Continuous Deployment](#continuous-integration--continuous-deployment)
- [License](#license)

## Features

- Mount any S3-compatible storage as a local volume
- Support for custom endpoints (AWS, MinIO, DigitalOcean Spaces, etc.)
- Multiple bucket mounting
- Configurable caching and performance options
- Health checking and monitoring
- Comprehensive logging
- S3 API Version Support
- Path-style vs Virtual-hosted style request configuration
- Advanced parallel operations and transfer optimizations
- **Multi-architecture support** (AMD64 and ARM64)
- **Enhanced Security**: Non-root operation, proper signal handling, and secure credential management
- **Improved Reliability**: Automatic mount retries and proper cleanup
- **s6 process supervisor**: Robust process management and service monitoring

## Quick Start

### Prerequisites

- Docker
- Docker Compose
- S3 bucket and credentials

### Basic Usage with Docker Compose

1. Create mount points with proper permissions:
   ```bash
   sudo mkdir -p s3data
   sudo chown 1000:1000 s3data  # Match container's s3fs user
   ```

2. Create a `.env` file with your credentials:
   ```bash
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   S3_BUCKET=your_bucket_name
   ```

3. Create a docker-compose.yml file:
   ```yaml
   version: '3'
   
   services:
     dockfuse:
       image: amizzo/dockfuse:latest
       container_name: dockfuse
       privileged: true
       user: "1000:1000"  # Run as non-root user
       env_file: .env
       volumes:
         - type: bind
           source: ${PWD}/s3data
           target: /mnt/s3bucket
           bind:
             propagation: rshared
       restart: unless-stopped
   ```

4. Start the container:
   ```bash
   docker-compose up -d
   ```

## Docker Compose Setup

### Standard Mount Configuration

```yaml
version: '3'

services:
  dockfuse:
    image: amizzo/dockfuse:latest
    container_name: dockfuse
    privileged: true # Required for FUSE mounts
    user: "1000:1000" # Use non-root user
    environment:
      - AWS_ACCESS_KEY_ID=your_access_key
      - AWS_SECRET_ACCESS_KEY=your_secret_key
      - S3_BUCKET=your_bucket_name
      # Optional settings
      - S3_PATH=/
      - DEBUG=0
      - S3_REGION=us-east-1
    volumes:
      - type: bind
        source: ./s3data
        target: /mnt/s3bucket
        bind:
          propagation: rshared # Important for mount visibility
    restart: unless-stopped
```

### Production-Ready Configuration

For robust production deployments:

```yaml
version: '3'

services:
  dockfuse:
    image: amizzo/dockfuse:latest
    container_name: dockfuse
    privileged: true
    user: "1000:1000"
    environment:
      - AWS_ACCESS_KEY_ID=your_access_key
      - AWS_SECRET_ACCESS_KEY=your_secret_key
      - S3_BUCKET=your_bucket_name
      # Performance tuning
      - PARALLEL_COUNT=10
      - MAX_THREAD_COUNT=10
      - MAX_STAT_CACHE_SIZE=2000
      - STAT_CACHE_EXPIRE=1800
      - MULTIPART_SIZE=20
      # Health check settings
      - HEALTH_CHECK_TIMEOUT=10
      - HEALTH_CHECK_WRITE_TEST=1
    volumes:
      - type: bind
        source: /mnt/persistent/s3data
        target: /mnt/s3bucket
        bind:
          propagation: rshared
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 30s
      timeout: 15s
      retries: 3
      start_period: 10s
    restart: unless-stopped
```

### Multiple Bucket Configuration

To mount multiple S3 buckets, use multiple containers:

```yaml
version: '3'

services:
  bucket1:
    image: amizzo/dockfuse:latest
    container_name: bucket1
    privileged: true
    user: "1000:1000"
    environment:
      - AWS_ACCESS_KEY_ID=your_access_key
      - AWS_SECRET_ACCESS_KEY=your_secret_key
      - S3_BUCKET=bucket1
    volumes:
      - type: bind
        source: ./bucket1
        target: /mnt/s3bucket
        bind:
          propagation: rshared
    restart: unless-stopped

  bucket2:
    image: amizzo/dockfuse:latest
    container_name: bucket2
    privileged: true
    user: "1000:1000"
    environment:
      - AWS_ACCESS_KEY_ID=your_access_key
      - AWS_SECRET_ACCESS_KEY=your_secret_key
      - S3_BUCKET=bucket2
    volumes:
      - type: bind
        source: ./bucket2
        target: /mnt/s3bucket
        bind:
          propagation: rshared
    restart: unless-stopped
```

## Mounting Options

### Mount Propagation

The `propagation` setting is critical for ensuring your S3 mount is visible:

- `rshared`: Bidirectional mount propagation (recommended)
- `shared`: Similar to rshared but less comprehensive
- `rslave`: Read-only mount propagation from host to container
- `slave`: Similar to rslave but less comprehensive
- `private`: No mount propagation (not recommended for S3 mounts)

Example:
```yaml
volumes:
  - type: bind
    source: ./s3data
    target: /mnt/s3bucket
    bind:
      propagation: rshared
```

### Persistent Mounts

For mounts that persist across container restarts:

```yaml
services:
  dockfuse:
    # ... other settings ...
    environment:
      # ... other environment variables ...
      - DISABLE_CLEANUP=1  # Don't unmount on container exit
      - SKIP_CLEANUP=1     # Don't handle unmounting on signals
    volumes:
      - type: bind
        source: /opt/persistent/s3data
        target: /mnt/s3bucket
        bind:
          propagation: rshared
```

### Named Volumes with Bind

```yaml
services:
  dockfuse:
    # ... other settings ...
    volumes:
      - s3data:/mnt/s3bucket

volumes:
  s3data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/mount/point
```

## Configuration

### Basic Options
- `AWS_ACCESS_KEY_ID`: Your AWS access key (required)
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key (required)
- `S3_BUCKET`: The S3 bucket to mount (required)
- `S3_PATH`: Path within the bucket to mount (default: `/`)
- `MOUNT_POINT`: Mount point inside the container (default: `/mnt/s3bucket`)
- `S3_URL`: S3 endpoint URL (default: `https://s3.amazonaws.com`)

### S3 API and Compatibility
- `S3_API_VERSION`: S3 API version to use (default: `default`)
- `S3_REGION`: S3 region to connect to (default: `us-east-1`)
- `USE_PATH_STYLE`: Use path-style requests (default: `false`)
- `S3_REQUEST_STYLE`: Explicit request style setting (`path` or `virtual`)

### Performance Tuning
- `PARALLEL_COUNT`: Number of parallel operations (default: `5`)
- `MAX_THREAD_COUNT`: Maximum number of threads (default: `5`)
- `MAX_STAT_CACHE_SIZE`: Maximum stat cache entries (default: `1000`)
- `STAT_CACHE_EXPIRE`: Stat cache expiration in seconds (default: `900`)
- `MULTIPART_SIZE`: Size in MB for multipart uploads (default: `10`)
- `MULTIPART_COPY_SIZE`: Size in MB for multipart copy (default: `512`)

### Cleanup and Persistence
- `DISABLE_CLEANUP`: Set to `1` to disable automatic cleanup on container exit
- `SKIP_CLEANUP`: Set to `1` to skip filesystem unmounting when receiving signals
- `TEST_MODE`: Set to `1` to skip S3 mounting and just execute the specified command

### Command and Entrypoint

The container uses [s6-overlay](https://github.com/just-containers/s6-overlay) as its init system for proper signal handling and process supervision.

- **Default Entrypoint**: `/init`
- **Default Command**: `/usr/local/bin/entrypoint.sh daemon`

To override the default command:

```yaml
# Override command to run a specific command after mounting
command: ["ls", "-la", "/mnt/s3bucket"]

# Test the container without mounting
environment:
  - TEST_MODE=1
command: ["echo", "Container works!"]
```

## Security Features

DockFuse includes several security enhancements:

1. **Non-root Operation**
   - Runs as a non-root user (UID 1000) by default
   - All mount points and cache directories are properly permissioned
   - AWS credentials are stored securely in the user's home directory

2. **Process Management**
   - Uses `s6-overlay` as init system for proper signal handling and process supervision
   - Automatic cleanup of mounts on container shutdown
   - Proper handling of SIGTERM and other signals

3. **Mount Reliability**
   - Automatic retry logic for failed mounts
   - Proper error handling and reporting
   - Health checks to verify mount status

## Health Monitoring

### Health Check Configuration

```yaml
services:
  dockfuse:
    # ... other config ...
    environment:
      - HEALTH_CHECK_TIMEOUT=10        # Timeout in seconds
      - HEALTH_CHECK_WRITE_TEST=1      # Enable write testing
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 1m
      timeout: 15s
      retries: 3
      start_period: 30s
```

### Monitoring Status

```bash
docker inspect --format='{{.State.Health.Status}}' dockfuse
```

## Troubleshooting

### Debug Mode

Enable verbose logging:
```yaml
environment:
  - DEBUG=1
```

### Common Issues

1. **Permission denied errors:**
   - Check that your host mount point has proper permissions:
     ```bash
     sudo chown 1000:1000 /path/to/mountpoint
     ```
   - Ensure your container has the `privileged: true` setting

2. **Mount disappears after container restart:**
   - Ensure you're using proper mount propagation: `propagation: rshared`
   - Consider using the `DISABLE_CLEANUP=1` and `SKIP_CLEANUP=1` options

3. **Mount not visible from other containers:**
   - Make sure you're using the correct mount propagation
   - Use `docker-compose down && docker-compose up -d` to restart all containers

4. **FUSE permission issues:**
   - Ensure the container runs with `privileged: true`
   - Check that FUSE is installed on the host

### Testing

1. **Simple container test:**
   ```bash
   docker run --rm -e TEST_MODE=1 amizzo/dockfuse:latest echo "Container works!"
   ```

2. **Check mount status:**
   ```bash
   docker exec dockfuse df -h
   docker exec dockfuse ls -la /mnt/s3bucket
   ```

3. **View container logs:**
   ```bash
   docker logs dockfuse
   ```

## Advanced Use Cases

### MinIO Configuration

```yaml
environment:
  - AWS_ACCESS_KEY_ID=minioadmin
  - AWS_SECRET_ACCESS_KEY=minioadmin
  - S3_BUCKET=data
  - S3_URL=http://minio:9000
  - USE_PATH_STYLE=true
```

### DigitalOcean Spaces

```yaml
environment:
  - AWS_ACCESS_KEY_ID=your_spaces_key
  - AWS_SECRET_ACCESS_KEY=your_spaces_secret
  - S3_BUCKET=your-space-name
  - S3_URL=https://nyc3.digitaloceanspaces.com
  - S3_REGION=nyc3
  - USE_PATH_STYLE=true
```

### High Performance Configuration

```yaml
environment:
  - PARALLEL_COUNT=10
  - MAX_THREAD_COUNT=10
  - MAX_STAT_CACHE_SIZE=5000
  - STAT_CACHE_EXPIRE=1800
  - MULTIPART_SIZE=20
```

## Continuous Integration / Continuous Deployment

This project uses GitHub Actions for CI/CD:

1. Builds multi-architecture Docker images (AMD64, ARM64)
2. Pushes images to Docker Hub with appropriate tags
3. Updates Docker Hub description

For CI/CD setup details, see [CI_CD_SETUP.md](CI_CD_SETUP.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.