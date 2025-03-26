# DockFuse

[![Docker Hub](https://img.shields.io/docker/pulls/amizzo/dockfuse.svg)](https://hub.docker.com/r/amizzo/dockfuse)

DockFuse is a Docker-based solution for mounting S3 buckets as local volumes using s3fs-fuse.

## Features

- Mount any S3-compatible storage as a local volume
- Support for custom endpoints (AWS, MinIO, DigitalOcean Spaces, etc.)
- Multiple bucket mounting
- Configurable caching and performance options
- Health checking
- Comprehensive logging
- S3 API Version Support
- Path-style vs Virtual-hosted style request configuration
- Advanced parallel operations
- Enhanced metadata and content caching
- Transfer optimizations
- Multi-architecture support (AMD64 and ARM64)

## Quick Start

### Prerequisites

- Docker
- Docker Compose
- S3 bucket and credentials

### Basic Usage

#### Option 1: Using Docker Hub Image

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

#### Option 2: Building Locally

1. Clone the repository:
   ```bash
   git clone https://github.com/amizzo/dockfuse.git
   cd dockfuse
   ```

2. Create a `.env` file with your credentials:
   ```bash
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   S3_BUCKET=your_bucket_name
   ```

3. Start the container:
   ```bash
   docker-compose up -d
   ```

4. Your S3 bucket is now mounted at `/mnt/s3bucket` in the container and available through the `s3data` Docker volume.

## Docker Hub

The DockFuse image is available on Docker Hub and can be pulled with:

```bash
docker pull amizzo/dockfuse:latest
```

### Using with docker run

```bash
docker run -d --name dockfuse \
  --privileged \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e S3_BUCKET=your_bucket_name \
  amizzo/dockfuse:latest
```

## Continuous Integration / Continuous Deployment

This project uses GitHub Actions for CI/CD. The workflow automatically:

1. Builds the Docker image when code is pushed to the main branch or when a new tag is created
2. Pushes the image to Docker Hub with appropriate tags
3. Updates the Docker Hub description from the DOCKER_HUB_README.md file

For details on setting up the CI/CD pipeline for your fork, see [CI_CD_SETUP.md](CI_CD_SETUP.md).

## Configuration Options

DockFuse provides a wide range of configuration options through environment variables:

### Basic Configuration
- `AWS_ACCESS_KEY_ID`: Your AWS access key (required)
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key (required)
- `S3_BUCKET`: The S3 bucket to mount (required)
- `S3_PATH`: Path within the bucket to mount (default: `/`)
- `MOUNT_POINT`: Mount point inside the container (default: `/mnt/s3bucket`)
- `S3_URL`: S3 endpoint URL (default: `https://s3.amazonaws.com`)

### S3 API and Compatibility
- `S3_API_VERSION`: S3 API version to use (default: `default`)
- `S3_REGION`: S3 region to connect to (default: `us-east-1`)

### Request Style
- `USE_PATH_STYLE`: Use path-style requests instead of virtual-hosted style (default: `false`)
- `S3_REQUEST_STYLE`: Explicit request style setting, either `path` or `virtual`

### Parallel Operations
- `PARALLEL_COUNT`: Number of parallel operations (default: `5`)
- `MAX_THREAD_COUNT`: Maximum number of threads for S3 operations (default: `5`)

### Caching
- `MAX_STAT_CACHE_SIZE`: Maximum number of entries in the stat cache (default: `1000`)
- `STAT_CACHE_EXPIRE`: Expiration time for stat cache entries in seconds (default: `900`)

### Transfer Optimizations
- `MULTIPART_SIZE`: Size in MB for multipart uploads (default: `10`)
- `MULTIPART_COPY_SIZE`: Size in MB for multipart copy limit (default: `512`)

### Health Check Options
- `HEALTH_CHECK_TIMEOUT`: Timeout in seconds for health check operations (default: `5`)
- `HEALTH_CHECK_WRITE_TEST`: Enable write test in health check when set to `1` (default: `0`)

### Additional Options
- `ADDITIONAL_OPTIONS`: Additional s3fs options as a comma-separated string
- `S3FS_OPTIONS`: Legacy s3fs options (default: `rw,allow_other,nonempty`)
- `DEBUG`: Enable debug logging when set to `1`

## Path-style vs Virtual-hosted Style

Amazon S3 supports two request styles:

1. **Virtual-hosted style** (default): `https://bucket-name.s3.amazonaws.com/key-name`
2. **Path-style**: `https://s3.amazonaws.com/bucket-name/key-name`

Path-style is required for buckets with periods in their names and for some S3-compatible services.

To use path-style, set:
```
USE_PATH_STYLE=true
```

Or specify the style explicitly:
```
S3_REQUEST_STYLE=path
```

## Examples

### MinIO Server

```yaml
environment:
  - AWS_ACCESS_KEY_ID=minioadmin
  - AWS_SECRET_ACCESS_KEY=minioadmin
  - S3_BUCKET=data
  - S3_URL=http://minio:9000
  - USE_PATH_STYLE=true
```

### Amazon S3 with Performance Tuning

```yaml
environment:
  - AWS_ACCESS_KEY_ID=your_access_key
  - AWS_SECRET_ACCESS_KEY=your_secret_key
  - S3_BUCKET=your_bucket
  - S3_REGION=us-west-2
  - PARALLEL_COUNT=10
  - MAX_THREAD_COUNT=10
  - MAX_STAT_CACHE_SIZE=5000
  - STAT_CACHE_EXPIRE=1800
  - MULTIPART_SIZE=20
```

## Advanced Use Cases

See the `examples` directory for more configuration examples.

## Troubleshooting

### Debug Mode

Set the `DEBUG` environment variable to `1` to enable verbose logging:

```yaml
environment:
  - DEBUG=1
```

### Health Check

You can monitor the health of your container with:

```bash
docker inspect --format='{{.State.Health.Status}}' dockfuse
```

To include a write test in the health check (more comprehensive but more intensive):

```yaml
environment:
  - HEALTH_CHECK_WRITE_TEST=1
```

#### Health Check in docker-compose.yml

Here's a more complete example of configuring health checks in your docker-compose.yml:

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
      - HEALTH_CHECK_TIMEOUT=10             # Increase timeout to 10 seconds
      - HEALTH_CHECK_WRITE_TEST=1           # Enable write testing
    volumes:
      - s3data:/mnt/s3bucket
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 1m                          # Check every minute
      timeout: 15s                          # Allow 15 seconds for the check
      retries: 3                            # Retry 3 times before marking unhealthy
      start_period: 30s                     # Give 30s for container to start
    restart: unless-stopped
    command: daemon
  
  # Example of a service that depends on the S3 mount being healthy
  dependent-service:
    image: your-application-image
    depends_on:
      dockfuse:
        condition: service_healthy          # Wait for healthy status before starting
    volumes:
      - s3data:/data:ro                     # Mount the same volume as read-only
    # Additional configuration...

volumes:
  s3data:
    driver: local
```

This configuration:
1. Configures container-level health check parameters
2. Increases the timeout for health checks to accommodate slower S3 connections
3. Enables write testing for more comprehensive checks
4. Ensures dependent services only start after the S3 mount is confirmed working

### Testing the Container

There are two ways to test if the container works correctly:

#### 1. Using TEST_MODE

For simple testing of the container without actually mounting an S3 bucket:

```bash
docker run --rm -e TEST_MODE=1 amizzo/dockfuse:latest echo "Container works!"
```

#### 2. Overriding the Entrypoint

You can also test by completely bypassing the entrypoint script:

```bash
docker run --rm --entrypoint="" amizzo/dockfuse:latest echo "Container works!"
```

#### 3. Full Functionality Test

To test the container with actual S3 mounting:

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e S3_BUCKET=your_bucket_name \
  amizzo/dockfuse:latest echo "Container with S3 mount works!"
```

### Common Issues

If you encounter permission issues, ensure your S3 bucket policy allows the required operations.

## License

This project is licensed under the MIT License - see the LICENSE file for details.