# Custom Endpoints Configuration

This example demonstrates how to configure DockFuse to work with various S3-compatible storage services using custom endpoints, regions, and API versions.

## Supported Services

This example includes configurations for:

1. **MinIO** - Self-hosted S3-compatible object storage
2. **DigitalOcean Spaces** - DigitalOcean's S3-compatible storage service
3. **Google Cloud Storage** - Using GCS with S3 compatibility
4. **Amazon S3** - Standard AWS S3 with specific API version

## Setup Instructions

### MinIO

1. Make sure you have a MinIO server running in a Docker network named `minio-network`.
2. Start the container:
   ```
   docker-compose up -d dockfuse-minio
   ```

### DigitalOcean Spaces

1. Create a `.env` file with your DigitalOcean Spaces credentials:
   ```
   DO_SPACES_KEY=your_spaces_key
   DO_SPACES_SECRET=your_spaces_secret
   DO_SPACES_BUCKET=your_spaces_bucket_name
   DO_SPACES_REGION=your_spaces_region (e.g., nyc3, sfo3, etc.)
   ```
2. Start the container:
   ```
   docker-compose up -d dockfuse-do-spaces
   ```

### Google Cloud Storage

1. Configure a `.env` file with your GCS credentials:
   ```
   GCS_ACCESS_KEY=your_gcs_hmac_key
   GCS_SECRET_KEY=your_gcs_hmac_secret
   GCS_BUCKET=your_gcs_bucket_name
   ```
2. Start the container:
   ```
   docker-compose up -d dockfuse-gcs
   ```

### Amazon S3

1. Configure a `.env` file with your AWS credentials:
   ```
   AWS_ACCESS_KEY_ID=your_aws_access_key
   AWS_SECRET_ACCESS_KEY=your_aws_secret_key
   S3_BUCKET=your_bucket_name
   ```
2. Start the container:
   ```
   docker-compose up -d dockfuse-aws
   ```

## Configuration Notes

### S3 API Version

Different storage providers may support different versions of the S3 API. This example shows:
- Using default API version for MinIO and DO Spaces
- Explicitly using API version 2 for GCS and Amazon S3

### Request Styles

- **Path-style requests** (`USE_PATH_STYLE=true`): Used for MinIO, DO Spaces, and GCS
- **Virtual-hosted style** (`USE_PATH_STYLE=false`): Used for the Amazon S3 example

### Custom Endpoints

The examples demonstrate different URL patterns:
- MinIO: `http://minio:9000`
- DO Spaces: `https://${DO_SPACES_REGION}.digitaloceanspaces.com`
- GCS: `https://storage.googleapis.com`
- AWS S3: Default S3 endpoint with region `us-west-2`

## Troubleshooting

All examples have `DEBUG=1` enabled, so you can view detailed logs with:

```
docker logs dockfuse-[service-name]
```

Where `[service-name]` is one of: `minio`, `do-spaces`, `gcs`, or `aws`. 