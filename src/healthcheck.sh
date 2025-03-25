#!/bin/bash

# Check if mount point exists
if [ ! -d "$MOUNT_POINT" ]; then
  echo "Mount point $MOUNT_POINT does not exist"
  exit 1
fi

# Check if mount point is a mount
if ! mountpoint -q "$MOUNT_POINT"; then
  echo "Mount point $MOUNT_POINT is not mounted"
  exit 1
fi

# Try to list directory contents
if ! ls -la "$MOUNT_POINT" > /dev/null 2>&1; then
  echo "Cannot list contents of $MOUNT_POINT"
  exit 1
fi

echo "Health check passed"
exit 0