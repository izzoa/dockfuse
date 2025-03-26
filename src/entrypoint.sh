#!/bin/bash
set -e

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up..."
    if mountpoint -q "${MOUNT_POINT}"; then
        fusermount -u "${MOUNT_POINT}"
    fi
}

# Set up signal handling
trap cleanup EXIT

# TEST_MODE allows running the container without S3 mounting
# When TEST_MODE=1, this script will skip S3 mounting and just execute the command
# Example: docker run -e TEST_MODE=1 amizzo/dockfuse echo "Test"
if [ "$TEST_MODE" = "1" ]; then
  echo "Running in TEST_MODE - S3 mounting skipped"
  exec "$@"
  exit 0
fi

# Create AWS credentials directory and file in user's home
mkdir -p "${HOME}/.aws"
echo "[default]" > "${HOME}/.aws/credentials"
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> "${HOME}/.aws/credentials"
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> "${HOME}/.aws/credentials"
chmod 600 "${HOME}/.aws/credentials"

# Set defaults for options
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
S3_URL=${S3_URL:-"https://s3.amazonaws.com"}

# Check for required variables
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$S3_BUCKET" ]; then
  echo "ERROR: Required environment variables not set."
  echo "Please provide:"
  echo "  - AWS_ACCESS_KEY_ID"
  echo "  - AWS_SECRET_ACCESS_KEY"
  echo "  - S3_BUCKET"
  exit 1
fi

# Build s3fs options
S3FS_OPTS="profile=default,allow_other"

# Add API version if specified
if [ "$S3_API_VERSION" != "default" ]; then
  S3FS_OPTS="$S3FS_OPTS,api_version=$S3_API_VERSION"
fi

# Add region if specified and not using a custom S3 endpoint
if [ -n "$S3_REGION" ] && [ "$S3_URL" = "https://s3.amazonaws.com" ]; then
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
S3FS_OPTS="$S3FS_OPTS,use_cache=/tmp/s3fs_cache,max_stat_cache_size=$MAX_STAT_CACHE_SIZE,stat_cache_expire=$STAT_CACHE_EXPIRE"

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
  echo "AWS credentials file:"
  # Print only first 4 chars of access key followed by asterisks
  ACCESS_KEY_MASKED=${AWS_ACCESS_KEY_ID:0:4}$(printf '%*s' $((${#AWS_ACCESS_KEY_ID} - 4)) | tr ' ' '*')
  # Print only first 4 chars of secret key followed by asterisks
  SECRET_KEY_MASKED=${AWS_SECRET_ACCESS_KEY:0:4}$(printf '%*s' $((${#AWS_SECRET_ACCESS_KEY} - 4)) | tr ' ' '*')
  echo "[default]"
  echo "aws_access_key_id = $ACCESS_KEY_MASKED"
  echo "aws_secret_access_key = $SECRET_KEY_MASKED"
fi

# Mount with retries
MAX_RETRIES=3
RETRY_COUNT=0

echo "Mounting $S3_BUCKET:$S3_PATH to $MOUNT_POINT"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if s3fs "$S3_BUCKET:$S3_PATH" "$MOUNT_POINT" \
        -o url="$S3_URL" \
        -o "$S3FS_OPTS"; then
        echo "Mount successful"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "Mount failed, retrying in 5 seconds (attempt $RETRY_COUNT of $MAX_RETRIES)..."
        sleep 5
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Failed to mount after ${MAX_RETRIES} attempts"
    exit 1
fi

# Keep the container running
if [ "$1" = "daemon" ]; then
    echo "Running in daemon mode..."
    # Use wait instead of tail -f for better signal handling
    wait
else
    # Execute the provided command
    exec "$@"
fi