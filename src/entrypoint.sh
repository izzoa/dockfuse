#!/bin/bash
set -e

# S6_BEHAVIOUR_IF_STAGE2_FAILS=2 should be set in the Dockerfile to ensure proper container exit

# When using s6, the entrypoint script is primarily responsible for:
# 1. Setting up credentials and configuration
# 2. Exporting variables for the s6 service to use
# 3. Executing custom commands if not in daemon mode

# Function to cleanup on exit - only used when not in daemon mode or TEST_MODE
# For daemon mode, the s6 service finish script handles cleanup
cleanup() {
    echo "Cleaning up resources..."
    if [ "${DISABLE_CLEANUP}" != "1" ] && [ "${SKIP_CLEANUP}" != "1" ]; then
        # Only attempt unmount if we're not in daemon mode (s6 handles that case)
        if [ "$DAEMON_MODE" != "1" ] && mountpoint -q "${MOUNT_POINT}"; then
            echo "Unmounting ${MOUNT_POINT}..."
            fusermount -u "${MOUNT_POINT}" || true
        fi
    else
        echo "Cleanup disabled by environment variable, keeping resources active"
    fi
}

# TEST_MODE allows running the container without S3 mounting
# When TEST_MODE=1, this script will skip S3 mounting and just execute the command
# Example: docker run -e TEST_MODE=1 amizzo/dockfuse echo "Test"
if [ "$TEST_MODE" = "1" ]; then
    echo "Running in TEST_MODE - S3 mounting skipped"
    # Execute the provided command
    exec "$@"
    exit 0
fi

# Set DAEMON_MODE flag based on first argument
if [ "$1" = "daemon" ]; then
    DAEMON_MODE=1
    echo "Running in daemon mode with s6..."
else
    DAEMON_MODE=0
    # Set up signal handling for non-daemon mode
    # In daemon mode, s6 handles signals and cleanup
    trap cleanup EXIT
fi

# Create AWS credentials directory and file in user's home
mkdir -p "${HOME}/.aws"
echo "[default]" > "${HOME}/.aws/credentials"
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> "${HOME}/.aws/credentials"
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> "${HOME}/.aws/credentials"
chmod 600 "${HOME}/.aws/credentials"

# Set defaults for options
: ${MOUNT_POINT:="/mnt/s3bucket"}
: ${S3_PATH:="/"}
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

# Build s3fs options for use by s6 service or direct mounting
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

# Export all variables needed by the s6 service
# These will be available to the s6 service via the with-contenv wrapper
export MOUNT_POINT
export S3_BUCKET
export S3_PATH
export S3FS_OPTS
export S3_URL
export DISABLE_CLEANUP
export SKIP_CLEANUP
export DEBUG

# Debug info
if [ "$DEBUG" = "1" ]; then
    echo "S3 bucket configuration:"
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
    echo "Disable Cleanup: ${DISABLE_CLEANUP:-0}"
    echo "Skip Cleanup: ${SKIP_CLEANUP:-0}"
    echo "Daemon Mode: $DAEMON_MODE"
    echo "AWS credentials file:"
    # Print only first 4 chars of access key followed by asterisks
    ACCESS_KEY_MASKED=${AWS_ACCESS_KEY_ID:0:4}$(printf '%*s' $((${#AWS_ACCESS_KEY_ID} - 4)) | tr ' ' '*')
    # Print only first 4 chars of secret key followed by asterisks
    SECRET_KEY_MASKED=${AWS_SECRET_ACCESS_KEY:0:4}$(printf '%*s' $((${#AWS_SECRET_ACCESS_KEY} - 4)) | tr ' ' '*')
    echo "[default]"
    echo "aws_access_key_id = $ACCESS_KEY_MASKED"
    echo "aws_secret_access_key = $SECRET_KEY_MASKED"
fi

# Handle command execution based on mode
if [ "$DAEMON_MODE" = "1" ]; then
    # In daemon mode, let s6 take over
    # The s6 service will handle the s3fs mounting and monitoring
    echo "Handing control to s6 for mount management and supervision..."
    exit 0
else
    # For non-daemon mode, we need to mount s3fs ourselves and then run the command
    echo "Mounting $S3_BUCKET:$S3_PATH to $MOUNT_POINT in direct command mode..."
    
    # Mount with retries for non-daemon mode
    MAX_RETRIES=3
    RETRY_COUNT=0
    
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
    
    # Execute the provided command
    echo "Executing command: $@"
    exec "$@"
fi