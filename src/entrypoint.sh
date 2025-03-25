#!/bin/bash
set -e

# Create AWS credentials directory and file
mkdir -p /root/.aws
echo "[default]" > /root/.aws/credentials
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /root/.aws/credentials
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /root/.aws/credentials
chmod 600 /root/.aws/credentials

# Set defaults for new options if not provided
S3_API_VERSION=${S3_API_VERSION:-"default"}
S3_REGION=${S3_REGION:-"us-east-1"}
USE_PATH_STYLE=${USE_PATH_STYLE:-"false"}
S3_REQUEST_STYLE=${S3_REQUEST_STYLE:-""}
PARALLEL_COUNT=${PARALLEL_COUNT:-"5"}
MAX_STAT_CACHE_SIZE=${MAX_STAT_CACHE_SIZE:-"1000"}
STAT_CACHE_EXPIRE=${STAT_CACHE_EXPIRE:-"900"}
MULTIPART_SIZE=${MULTIPART_SIZE:-"10"}
MULTIPART_COPY_SIZE=${MULTIPART_COPY_SIZE:-"512"}
MAX_THREAD_COUNT=${MAX_THREAD_COUNT:-"5"}
ADDITIONAL_OPTIONS=${ADDITIONAL_OPTIONS:-""}

# Build s3fs options
S3FS_OPTS="profile=default"

# Add API version if specified
if [ "$S3_API_VERSION" != "default" ]; then
  S3FS_OPTS="$S3FS_OPTS,api_version=$S3_API_VERSION"
fi

# Add region if specified
if [ -n "$S3_REGION" ]; then
  S3FS_OPTS="$S3FS_OPTS,region=$S3_REGION"
fi

# Configure request style (path vs virtual-hosted)
if [ "$USE_PATH_STYLE" = "true" ] || [ "$S3_REQUEST_STYLE" = "path" ]; then
  S3FS_OPTS="$S3FS_OPTS,use_path_request_style"
elif [ "$S3_REQUEST_STYLE" = "virtual" ]; then
  S3FS_OPTS="$S3FS_OPTS,use_virtualhost_request_style"
fi

# Configure parallel operations
S3FS_OPTS="$S3FS_OPTS,parallel_count=$PARALLEL_COUNT,max_thread_count=$MAX_THREAD_COUNT"

# Configure advanced caching
S3FS_OPTS="$S3FS_OPTS,use_cache=/tmp,max_stat_cache_size=$MAX_STAT_CACHE_SIZE,stat_cache_expire=$STAT_CACHE_EXPIRE"

# Configure transfer optimizations
S3FS_OPTS="$S3FS_OPTS,multipart_size=${MULTIPART_SIZE},singlepart_copy_limit=${MULTIPART_COPY_SIZE}"

# Add any additional user-specified options
if [ -n "$ADDITIONAL_OPTIONS" ]; then
  S3FS_OPTS="$S3FS_OPTS,$ADDITIONAL_OPTIONS"
fi

# Add user-specified options
if [ -n "$S3FS_OPTIONS" ]; then
  S3FS_OPTS="$S3FS_OPTS,$S3FS_OPTIONS"
fi

# Debug info
if [ "$DEBUG" = "1" ]; then
  echo "Mounting S3 bucket with the following settings:"
  echo "Bucket: $S3_BUCKET"
  echo "Path: $S3_PATH"
  echo "Mount point: $MOUNT_POINT"
  echo "S3 URL: $S3_URL"
  echo "S3 Region: $S3_REGION"
  echo "S3 API Version: $S3_API_VERSION" 
  echo "Use Path Style: $USE_PATH_STYLE"
  echo "Request Style: $S3_REQUEST_STYLE"
  echo "Parallel Count: $PARALLEL_COUNT"
  echo "Max Thread Count: $MAX_THREAD_COUNT"
  echo "Max Stat Cache Size: $MAX_STAT_CACHE_SIZE"
  echo "Stat Cache Expire: $STAT_CACHE_EXPIRE"
  echo "Multipart Size: $MULTIPART_SIZE MB"
  echo "Multipart Copy Size: $MULTIPART_COPY_SIZE MB"
  echo "Additional Options: $ADDITIONAL_OPTIONS"
  echo "S3FS Options: $S3FS_OPTS"
  echo "AWS credentials file content:"
  cat /root/.aws/credentials
fi

# Mount the S3 bucket
echo "Mounting $S3_BUCKET:$S3_PATH to $MOUNT_POINT"
s3fs "$S3_BUCKET:$S3_PATH" "$MOUNT_POINT" \
  -o url="$S3_URL" \
  -o $S3FS_OPTS

# Keep the container running
if [ "$1" = "daemon" ]; then
  echo "Running in daemon mode..."
  # Run in foreground to keep container alive
  tail -f /dev/null
else
  # Execute the provided command
  exec "$@"
fi