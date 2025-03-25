# DockFuse

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

## Quick Start

### Prerequisites

- Docker
- Docker Compose
- S3 bucket and credentials

### Basic Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dockfuse.git
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

### Common Issues

If you encounter permission issues, ensure your S3 bucket policy allows the required operations.

## License

This project is licensed under the MIT License - see the LICENSE file for details.