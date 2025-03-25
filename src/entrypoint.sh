#!/bin/bash
set -e

# Create AWS credentials directory and file
mkdir -p /root/.aws
echo "[default]" > /root/.aws/credentials
echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /root/.aws/credentials
echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /root/.aws/credentials
chmod 600 /root/.aws/credentials

# Debug info
if [ "$DEBUG" = "1" ]; then
  echo "Mounting S3 bucket with the following settings:"
  echo "Bucket: $S3_BUCKET"
  echo "Path: $S3_PATH"
  echo "Mount point: $MOUNT_POINT"
  echo "S3 URL: $S3_URL"
  echo "Options: $S3FS_OPTIONS"
  echo "AWS credentials file content:"
  cat /root/.aws/credentials
fi

# Mount the S3 bucket
echo "Mounting $S3_BUCKET:$S3_PATH to $MOUNT_POINT"
s3fs "$S3_BUCKET:$S3_PATH" "$MOUNT_POINT" \
  -o url="$S3_URL" \
  -o profile=default \
  -o $S3FS_OPTIONS

# Keep the container running
if [ "$1" = "daemon" ]; then
  echo "Running in daemon mode..."
  # Run in foreground to keep container alive
  tail -f /dev/null
else
  # Execute the provided command
  exec "$@"
fi