#!/bin/bash
set -e

# Health check variables
HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-5}
HEALTH_CHECK_WRITE_TEST=${HEALTH_CHECK_WRITE_TEST:-0}

# Check if mount point exists
if [ ! -d "$MOUNT_POINT" ]; then
  echo "ERROR: Mount point $MOUNT_POINT does not exist"
  exit 1
fi

# Check if mount point is a mount
if ! timeout $HEALTH_CHECK_TIMEOUT mountpoint -q "$MOUNT_POINT"; then
  echo "ERROR: Mount point $MOUNT_POINT is not mounted"
  exit 1
fi

# Try to list directory contents
if ! timeout $HEALTH_CHECK_TIMEOUT ls -la "$MOUNT_POINT" > /dev/null 2>&1; then
  echo "ERROR: Cannot list contents of $MOUNT_POINT"
  exit 1
fi

# Optional write test
if [ "$HEALTH_CHECK_WRITE_TEST" = "1" ]; then
  TEST_FILE="$MOUNT_POINT/.s3fs_health_check"
  TEST_CONTENT="DockFuse health check $(date)"
  
  # Try to write a test file
  if ! echo "$TEST_CONTENT" | timeout $HEALTH_CHECK_TIMEOUT tee "$TEST_FILE" > /dev/null 2>&1; then
    echo "ERROR: Cannot write to $MOUNT_POINT"
    exit 1
  fi
  
  # Try to read the test file
  if ! timeout $HEALTH_CHECK_TIMEOUT cat "$TEST_FILE" > /dev/null 2>&1; then
    echo "ERROR: Cannot read from $MOUNT_POINT"
    rm -f "$TEST_FILE" || true
    exit 1
  fi
  
  # Clean up
  timeout $HEALTH_CHECK_TIMEOUT rm -f "$TEST_FILE" || true
  
  echo "Health check passed with write test"
else
  echo "Health check passed (read-only)"
fi

exit 0