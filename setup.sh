#!/bin/bash
set -e

# Welcome banner
echo "======================================"
echo "DockFuse Setup Script"
echo "======================================"
echo "This script will help you create a .env file with your S3 configuration."
echo

# Check if .env already exists
if [ -f .env ]; then
  read -p ".env file already exists. Do you want to overwrite it? (y/n): " overwrite
  if [ "$overwrite" != "y" ]; then
    echo "Setup cancelled. Your existing .env file was not modified."
    exit 0
  fi
fi

# Basic configuration
echo "=== Basic Configuration ==="
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "S3 Bucket Name: " S3_BUCKET
read -p "S3 Path within bucket (default: /): " S3_PATH
S3_PATH=${S3_PATH:-/}

# S3 Endpoint
read -p "S3 URL (default: https://s3.amazonaws.com): " S3_URL
S3_URL=${S3_URL:-https://s3.amazonaws.com}

# S3 API and Region
read -p "S3 Region (default: us-east-1): " S3_REGION
S3_REGION=${S3_REGION:-us-east-1}
read -p "S3 API Version (default: default): " S3_API_VERSION
S3_API_VERSION=${S3_API_VERSION:-default}

# Request Style
read -p "Use path-style requests? (true/false, default: false): " USE_PATH_STYLE
USE_PATH_STYLE=${USE_PATH_STYLE:-false}

# Advanced configuration
echo
echo "=== Advanced Configuration ==="
echo "Do you want to configure advanced options? This includes:"
echo "- Parallel operations"
echo "- Caching"
echo "- Transfer optimizations"
echo "- Health check options"
read -p "Configure advanced options? (y/n, default: n): " configure_advanced
configure_advanced=${configure_advanced:-n}

if [ "$configure_advanced" = "y" ]; then
  # Parallel Operations
  read -p "Parallel Count (default: 5): " PARALLEL_COUNT
  PARALLEL_COUNT=${PARALLEL_COUNT:-5}
  read -p "Max Thread Count (default: 5): " MAX_THREAD_COUNT
  MAX_THREAD_COUNT=${MAX_THREAD_COUNT:-5}
  
  # Caching
  read -p "Max Stat Cache Size (default: 1000): " MAX_STAT_CACHE_SIZE
  MAX_STAT_CACHE_SIZE=${MAX_STAT_CACHE_SIZE:-1000}
  read -p "Stat Cache Expire seconds (default: 900): " STAT_CACHE_EXPIRE
  STAT_CACHE_EXPIRE=${STAT_CACHE_EXPIRE:-900}
  
  # Transfer Optimizations
  read -p "Multipart Size in MB (default: 10): " MULTIPART_SIZE
  MULTIPART_SIZE=${MULTIPART_SIZE:-10}
  read -p "Multipart Copy Size in MB (default: 512): " MULTIPART_COPY_SIZE
  MULTIPART_COPY_SIZE=${MULTIPART_COPY_SIZE:-512}
  
  # Health Check
  read -p "Health Check Timeout seconds (default: 5): " HEALTH_CHECK_TIMEOUT
  HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-5}
  read -p "Enable Health Check Write Test? (0/1, default: 0): " HEALTH_CHECK_WRITE_TEST
  HEALTH_CHECK_WRITE_TEST=${HEALTH_CHECK_WRITE_TEST:-0}
  
  # Additional Options
  read -p "Additional s3fs Options (comma-separated, default: empty): " ADDITIONAL_OPTIONS
fi

# Debug mode
read -p "Enable debug logging? (0/1, default: 1): " DEBUG
DEBUG=${DEBUG:-1}

# Write the .env file
cat > .env << EOF
# DockFuse Configuration
# Created: $(date)

# Basic Configuration
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
S3_BUCKET=$S3_BUCKET
S3_PATH=$S3_PATH
S3_URL=$S3_URL

# S3 API and Region
S3_REGION=$S3_REGION
S3_API_VERSION=$S3_API_VERSION

# Request Style
USE_PATH_STYLE=$USE_PATH_STYLE

EOF

# Add advanced configuration if requested
if [ "$configure_advanced" = "y" ]; then
  cat >> .env << EOF
# Parallel Operations
PARALLEL_COUNT=$PARALLEL_COUNT
MAX_THREAD_COUNT=$MAX_THREAD_COUNT

# Caching
MAX_STAT_CACHE_SIZE=$MAX_STAT_CACHE_SIZE
STAT_CACHE_EXPIRE=$STAT_CACHE_EXPIRE

# Transfer Optimizations
MULTIPART_SIZE=$MULTIPART_SIZE
MULTIPART_COPY_SIZE=$MULTIPART_COPY_SIZE

# Health Check
HEALTH_CHECK_TIMEOUT=$HEALTH_CHECK_TIMEOUT
HEALTH_CHECK_WRITE_TEST=$HEALTH_CHECK_WRITE_TEST

EOF

  # Add additional options if not empty
  if [ -n "$ADDITIONAL_OPTIONS" ]; then
    echo "# Additional Options" >> .env
    echo "ADDITIONAL_OPTIONS=$ADDITIONAL_OPTIONS" >> .env
    echo >> .env
  fi
fi

# Add debug setting
echo "# Debug" >> .env
echo "DEBUG=$DEBUG" >> .env

echo
echo "======================================"
echo ".env file has been created successfully!"
echo "To start DockFuse, run:"
echo "docker-compose up -d"
echo "======================================"

chmod +x setup.sh 