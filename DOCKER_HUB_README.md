# DockFuse

Docker container for mounting S3 buckets as local volumes using s3fs-fuse.

**GitHub Repository:** [https://github.com/amizzo/dockfuse](https://github.com/amizzo/dockfuse)

## Features

- Mount any S3-compatible storage as a local volume
- Support for custom endpoints (AWS, MinIO, DigitalOcean Spaces, etc.)
- Multiple bucket mounting
- Configurable caching and performance options
- Health checking and monitoring
- S3 API Version Support
- Path-style vs Virtual-hosted style request configuration
- Advanced parallel operations and transfer optimizations

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

## Advanced Usage

For advanced configuration options, example configurations, and more information, visit the [GitHub repository](https://github.com/amizzo/dockfuse). 