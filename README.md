# DockFuse

[![Docker Hub](https://img.shields.io/docker/pulls/amizzo/dockfuse.svg)](https://hub.docker.com/r/amizzo/dockfuse)

DockFuse is a Docker-based solution for mounting S3 buckets as local volumes using s3fs-fuse.

## Table of Contents
- [Features](#features)
- [Quick Start](#quick-start)
- [Security Features](#security-features)
- [Configuration](#configuration)
- [Volume Sharing](#volume-sharing)
- [Health Monitoring](#health-monitoring)
- [Troubleshooting](#troubleshooting)
- [Advanced Use Cases](#advanced-use-cases)
- [CI/CD](#continuous-integration--continuous-deployment)
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

## Quick Start

### Prerequisites

- Docker
- Docker Compose
- S3 bucket and credentials

### Basic Usage

#### Option 1: Using Docker Hub Image

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
       command: daemon
   ```

4. Start the container:
   ```bash
   docker-compose up -d
   ```

#### Option 2: Using docker run

```bash
# Create mount point
sudo mkdir -p s3data
sudo chown 1000:1000 s3data

# Run container
docker run -d --name dockfuse \
  --privileged \
  --user 1000:1000 \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e S3_BUCKET=your_bucket_name \
  -v ${PWD}/s3data:/mnt/s3bucket:rshared \
  amizzo/dockfuse:latest
```

## Security Features

DockFuse includes several security enhancements:

1. **Non-root Operation**
   - Runs as a non-root user (UID 1000) by default
   - All mount points and cache directories are properly permissioned
   - AWS credentials are stored securely in the user's home directory

2. **Process Management**
   - Uses `tini` as init system for proper signal handling
   - Automatic cleanup of mounts on container shutdown
   - Proper handling of SIGTERM and other signals

3. **Mount Reliability**
   - Automatic retry logic for failed mounts
   - Proper error handling and reporting
   - Health checks to verify mount status

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

## Volume Sharing

DockFuse supports several methods for sharing S3 mounts between containers:

1. **Mount Propagation** (Recommended)
   ```yaml
   volumes:
     - type: bind
       source: ./s3data
       target: /mnt/s3bucket
       bind:
         propagation: rshared
   ```

2. **Named Volumes with Bind Driver**
   ```yaml
   volumes:
     s3data:
       driver: local
       driver_opts:
         type: none
         o: bind
         device: ${PWD}/s3data
   ```

3. **Direct Container Sharing**
   ```yaml
   volumes_from:
     - dockfuse:ro  # Read-only access
   ```

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

1. **Missing environment variables:**
   - Verify `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `S3_BUCKET`

2. **Permissions issues:**
   - Check AWS credentials permissions
   - Verify bucket accessibility
   - Ensure proper mount point permissions

3. **FUSE/Docker issues:**
   - Verify `privileged: true` setting
   - Install FUSE dependencies if needed
   - Check mount propagation settings

### Testing

1. **Simple container test:**
   ```bash
   docker run --rm -e TEST_MODE=1 amizzo/dockfuse:latest echo "Container works!"
   ```

2. **Bypass entrypoint test:**
   ```bash
   docker run --rm --entrypoint="" amizzo/dockfuse:latest echo "Container works!"
   ```

3. **Mount test:**
   ```bash
   docker run --rm \
     -e AWS_ACCESS_KEY_ID=your_access_key \
     -e AWS_SECRET_ACCESS_KEY=your_secret_key \
     -e S3_BUCKET=your_bucket_name \
     amizzo/dockfuse:latest echo "Container with S3 mount works!"
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

### High Performance Configuration

```yaml
environment:
  - S3_REGION=us-west-2
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