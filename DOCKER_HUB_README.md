# DockFuse

Docker container for mounting S3 buckets as local volumes using s3fs-fuse.

**GitHub Repository:** [https://github.com/izzoa/dockfuse](https://github.com/izzoa/dockfuse)

## Features

- Mount any S3-compatible storage as a local volume
- Support for custom endpoints (AWS, MinIO, DigitalOcean Spaces, etc.)
- Multiple bucket mounting capabilities
- Configurable caching and performance options
- Health checking and monitoring
- S3 API Version Support
- Path-style vs Virtual-hosted style request configuration
- Advanced parallel operations and transfer optimizations
- **Multi-architecture support**: Works on both ARM64 (Apple Silicon, Raspberry Pi) and AMD64 (x86-64) systems
- **Enhanced Security**: Non-root operation, proper signal handling, and secure credential management
- **Improved Reliability**: Automatic mount retries and proper cleanup
- **s6 process supervisor**: Robust process management and service monitoring

## Quick Start with Docker Compose

### Step 1: Create mount directory and set permissions

```bash
sudo mkdir -p s3data
sudo chown 1000:1000 s3data  # Match container's s3fs user
```

### Step 2: Create .env file with credentials

```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your_bucket_name
```

### Step 3: Create docker-compose.yml

```yaml
version: '3'

services:
  dockfuse:
    image: amizzo/dockfuse:latest
    container_name: dockfuse
    privileged: true  # Required for FUSE mounts
    user: "1000:1000"  # Run as non-root user
    env_file: .env
    volumes:
      - type: bind
        source: ${PWD}/s3data
        target: /mnt/s3bucket
        bind:
          propagation: rshared  # Critical for mount visibility
    restart: unless-stopped
```

### Step 4: Launch the container

```bash
docker-compose up -d
```

### Step 5: Verify the mount

```bash
# Check S3 mount in container filesystem
docker exec dockfuse df -h

# List contents of S3 bucket
docker exec dockfuse ls -la /mnt/s3bucket
```

## Recommended Production Configuration

For production deployments, use this enhanced configuration:

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
      # Health check settings
      - HEALTH_CHECK_TIMEOUT=10
      - HEALTH_CHECK_WRITE_TEST=1
    volumes:
      - type: bind
        source: /mnt/persistent/s3data  # Use persistent storage location
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

## Multiple Bucket Configuration

To mount multiple S3 buckets simultaneously:

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

## Critical Configuration Options

### Mount Propagation (Important!)

The `propagation` setting is essential for ensuring your S3 mount is properly visible:

```yaml
volumes:
  - type: bind
    source: ./s3data
    target: /mnt/s3bucket
    bind:
      propagation: rshared  # Required for proper mount visibility
```

### Persistent Mounts

For mounts that persist across container restarts:

```yaml
environment:
  # Your other environment variables...
  - DISABLE_CLEANUP=1  # Don't unmount on container exit
  - SKIP_CLEANUP=1     # Don't handle unmounting on signals
```

## Basic Configuration Options

- `AWS_ACCESS_KEY_ID`: Your AWS access key (required)
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key (required)
- `S3_BUCKET`: The S3 bucket to mount (required)
- `S3_PATH`: Path within the bucket to mount (default: `/`)
- `S3_URL`: S3 endpoint URL (default: `https://s3.amazonaws.com`)
- `S3_REGION`: S3 region to connect to (default: `us-east-1`)
- `USE_PATH_STYLE`: Use path-style requests (default: `false`)
- `DEBUG`: Enable debug logging (default: `0`)

## Alternative S3-Compatible Storage

### MinIO

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

## Health Check Configuration

DockFuse includes built-in health checking:

```yaml
environment:
  # Your other environment variables...
  - HEALTH_CHECK_TIMEOUT=10        # Timeout in seconds (default: 5)
  - HEALTH_CHECK_WRITE_TEST=1      # Enable write test (default: 0)
healthcheck:
  test: ["CMD", "/usr/local/bin/healthcheck.sh"]
  interval: 30s
  timeout: 15s
  retries: 3
  start_period: 10s
```

## Troubleshooting

### Debug Mode

```yaml
environment:
  - DEBUG=1  # Enable verbose logging
```

### Common Issues

1. **Permission denied errors:** Check that your host mount point has proper permissions:
   ```bash
   sudo chown 1000:1000 /path/to/mountpoint
   ```

2. **Mount not visible:** Ensure you're using the proper mount propagation setting:
   ```yaml
   volumes:
     - type: bind
       source: ./s3data
       target: /mnt/s3bucket
       bind:
         propagation: rshared
   ```

3. **Mount disappears after restart:** Use the persistence settings:
   ```yaml
   environment:
     - DISABLE_CLEANUP=1
     - SKIP_CLEANUP=1
   ```

## Testing the Container

```bash
# Run with test mode (no mount)
docker run --rm -e TEST_MODE=1 amizzo/dockfuse:latest echo "Container works!"

# Check container logs
docker logs dockfuse

# Check mount status
docker exec dockfuse df -h
docker exec dockfuse ls -la /mnt/s3bucket
```

## Command Overrides

The container uses `/usr/local/bin/entrypoint.sh daemon` as its default command. To run a custom command instead:

```yaml
# Execute a custom command after mounting
command: ["ls", "-la", "/mnt/s3bucket"]

# Run in test mode without mounting
environment:
  - TEST_MODE=1
command: ["echo", "Container works!"]
```

For advanced configuration options and more information, visit the [GitHub repository](https://github.com/izzoa/dockfuse). 