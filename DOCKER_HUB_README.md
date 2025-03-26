# DockFuse

Docker container for mounting S3 buckets as local volumes using s3fs-fuse.

**GitHub Repository:** [https://github.com/izzoa/dockfuse](https://github.com/izzoa/dockfuse)

## Features

- Mount any S3-compatible storage as a local volume
- Support for custom endpoints (AWS, MinIO, DigitalOcean Spaces, etc.)
- Multiple bucket mounting
- Configurable caching and performance options
- Health checking and monitoring
- S3 API Version Support
- Path-style vs Virtual-hosted style request configuration
- Advanced parallel operations and transfer optimizations
- **Multi-architecture support**: Works on both ARM64 (Apple Silicon, Raspberry Pi) and AMD64 (x86-64) systems

## Quick Start

### Using docker-compose (recommended)

1. Create a `.env` file with your credentials:
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your_bucket_name
```

2. Create a docker-compose.yml file:
```yaml
version: '3'

services:
  dockfuse:
    image: amizzo/dockfuse:latest
    container_name: dockfuse
    privileged: true
    env_file: .env
    volumes:
      - s3data:/mnt/s3bucket
    restart: unless-stopped
    command: daemon

volumes:
  s3data:
    driver: local
```

3. Start the container:
```bash
docker-compose up -d
```

### Using docker run

```bash
docker run -d --name dockfuse \
  --privileged \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e S3_BUCKET=your_bucket_name \
  amizzo/dockfuse:latest
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

## Testing the Container

To test the container without actually mounting an S3 bucket:

```bash
docker run --rm -e TEST_MODE=1 amizzo/dockfuse:latest echo "Container works!"
```

Or by bypassing the entrypoint script:

```bash
docker run --rm --entrypoint="" amizzo/dockfuse:latest echo "Container works!"
```

## Health Check Configuration

DockFuse includes built-in health checking to monitor the S3 mount status. Here's how to use it:

### Health Check with Docker Compose

```yaml
version: '3'

services:
  dockfuse:
    image: amizzo/dockfuse:latest
    container_name: dockfuse
    privileged: true
    environment:
      - AWS_ACCESS_KEY_ID=your_access_key
      - AWS_SECRET_ACCESS_KEY=your_secret_key
      - S3_BUCKET=your_bucket_name
      # Health check configuration
      - HEALTH_CHECK_TIMEOUT=10        # Timeout in seconds (default: 5)
      - HEALTH_CHECK_WRITE_TEST=1      # Enable write test (default: 0)
    volumes:
      - s3data:/mnt/s3bucket
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 1m
      timeout: 15s
      retries: 3
      start_period: 30s
    restart: unless-stopped

volumes:
  s3data:
    driver: local
```

### Monitoring Health Status

Check the health status of your container:

```bash
docker inspect --format='{{.State.Health.Status}}' dockfuse
```

The health check verifies that:
1. The S3 bucket is mounted correctly
2. Directory contents can be listed
3. (Optional) Files can be written and read when `HEALTH_CHECK_WRITE_TEST=1`

## Advanced Usage

For advanced configuration options, example configurations, and more information, visit the [GitHub repository](https://github.com/izzoa/dockfuse). 