# High-Performance Configuration

This example demonstrates a high-performance configuration for DockFuse, optimized for workloads that require maximum throughput and minimal latency.

## Features

- **Increased Parallelism**: Uses 20 parallel operations and threads for high throughput
- **Enhanced Metadata Caching**: Larger cache size (10,000 entries) and longer expiration (1,800 seconds)
- **Optimized Transfer Settings**: Larger multipart size (25 MB) and copy size (1,024 MB)
- **Advanced Cache Options**: Enables non-object caching and complementary stat information
- **Network Optimizations**: Disables DNS caching to prevent stale DNS records
- **Data Integrity**: Enables content MD5 checking for data validation

## Usage

### Option 1: Using Docker Hub (Recommended)

1. Create a `.env` file with your S3 credentials:
```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your_bucket_name
S3_REGION=your_region
```

2. Create a docker-compose.yml file:
```yaml
version: '3'

services:
  dockfuse-high-performance:
    image: amizzo/dockfuse:latest
    container_name: dockfuse-high-performance
    privileged: true
    env_file: .env
    environment:
      - S3_PATH=/
      - MOUNT_POINT=/mnt/s3bucket
      - S3_URL=https://s3.amazonaws.com
      
      # High-performance parallel operations
      - PARALLEL_COUNT=20
      - MAX_THREAD_COUNT=20
      
      # Optimized caching for metadata
      - MAX_STAT_CACHE_SIZE=10000
      - STAT_CACHE_EXPIRE=1800
      
      # Transfer optimizations
      - MULTIPART_SIZE=25
      - MULTIPART_COPY_SIZE=1024
      
      # Additional performance options
      - ADDITIONAL_OPTIONS=enable_noobj_cache,complement_stat,nodnscache,enable_content_md5
      
      - DEBUG=1
    volumes:
      - s3data-high-perf:/mnt/s3bucket
    restart: unless-stopped
    command: daemon

volumes:
  s3data-high-perf:
    driver: local
```

3. Start the high-performance container:
```
docker-compose up -d
```

### Option 2: Building Locally

1. Create a `.env` file with your S3 credentials:
```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your_bucket_name
S3_REGION=your_region
```

2. Start the high-performance container:
```
docker-compose up -d
```

## Performance Considerations

This configuration is optimized for:
- High-bandwidth network connections
- Large file operations
- Scenarios where metadata caching provides significant benefits
- Environments where multiple concurrent users access the mounted filesystem

## Monitoring Performance

Since this configuration enables debug logging (`DEBUG=1`), you can monitor performance by viewing the container logs:

```
docker logs dockfuse-high-performance
```

## Tuning

You may need to adjust these parameters based on your specific workload and network conditions:

- Reduce `PARALLEL_COUNT` and `MAX_THREAD_COUNT` on systems with limited CPU resources
- Adjust `MAX_STAT_CACHE_SIZE` based on how many unique files you access
- Modify `MULTIPART_SIZE` based on your average file size and network conditions 