#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${YELLOW}======================================"
echo "DockFuse Test Script"
echo -e "======================================${NC}"

# Check if docker is running
echo -n "Checking if Docker is running... "
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}FAILED${NC}"
  echo "Docker is not running. Please start Docker and try again."
  exit 1
else
  echo -e "${GREEN}OK${NC}"
fi

# Check if env file exists
echo -n "Checking if .env file exists... "
if [ ! -f .env ]; then
  echo -e "${RED}FAILED${NC}"
  echo "The .env file does not exist. Please run setup.sh first."
  exit 1
else
  echo -e "${GREEN}OK${NC}"
fi

# Check if required env variables are set
echo -n "Checking required environment variables... "
source .env
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$S3_BUCKET" ]; then
  echo -e "${RED}FAILED${NC}"
  echo "Required environment variables are not set. Please check your .env file."
  exit 1
else
  echo -e "${GREEN}OK${NC}"
fi

# Check if container is already running
echo -n "Checking if DockFuse container is already running... "
if docker ps | grep -q "dockfuse"; then
  echo -e "${YELLOW}FOUND${NC}"
  echo "DockFuse container is already running."
  
  # Check container health
  echo -n "Checking container health... "
  health=$(docker inspect --format='{{.State.Health.Status}}' dockfuse 2>/dev/null || echo "unknown")
  if [ "$health" = "healthy" ]; then
    echo -e "${GREEN}HEALTHY${NC}"
  elif [ "$health" = "starting" ]; then
    echo -e "${YELLOW}STARTING${NC}"
    echo "Container is still initializing. Please wait a moment and try again."
  else
    echo -e "${RED}UNHEALTHY${NC}"
    echo "Container is running but not healthy. Check logs with 'docker logs dockfuse'."
  fi
else
  echo -e "${YELLOW}NOT FOUND${NC}"
  
  # Ask if user wants to start the container
  read -p "Do you want to start the DockFuse container? (y/n): " start_container
  if [ "$start_container" = "y" ]; then
    echo "Starting DockFuse container..."
    docker-compose up -d
    
    echo "Waiting for container to start..."
    sleep 5
    
    # Check if container started successfully
    if docker ps | grep -q "dockfuse"; then
      echo -e "${GREEN}Container started successfully.${NC}"
      
      echo "Waiting for health check..."
      for i in {1..12}; do
        health=$(docker inspect --format='{{.State.Health.Status}}' dockfuse 2>/dev/null || echo "unknown")
        if [ "$health" = "healthy" ]; then
          echo -e "${GREEN}Container is healthy!${NC}"
          break
        elif [ "$health" = "unhealthy" ]; then
          echo -e "${RED}Container is unhealthy.${NC}"
          echo "Check logs with 'docker logs dockfuse'."
          break
        fi
        
        if [ $i -eq 12 ]; then
          echo -e "${YELLOW}Health check still in progress...${NC}"
          echo "You can check status later with 'docker inspect --format=\"{{.State.Health.Status}}\" dockfuse'"
        else
          echo -n "."
          sleep 5
        fi
      done
    else
      echo -e "${RED}Failed to start container.${NC}"
      echo "Check logs with 'docker-compose logs'."
      exit 1
    fi
  fi
fi

# Test file operations if container is running and healthy
if docker ps | grep -q "dockfuse" && [ "$(docker inspect --format='{{.State.Health.Status}}' dockfuse 2>/dev/null)" = "healthy" ]; then
  echo -e "\n${YELLOW}Do you want to test file operations?${NC}"
  echo "This will create a test file in your S3 bucket."
  read -p "Run file operations test? (y/n): " test_files
  
  if [ "$test_files" = "y" ]; then
    echo "Testing file operations..."
    
    # Create a test file
    test_content="DockFuse test file - $(date)"
    test_file="dockfuse_test_$(date +%s).txt"
    
    echo -n "Creating test file... "
    if docker exec dockfuse bash -c "echo '$test_content' > /mnt/s3bucket/$test_file"; then
      echo -e "${GREEN}OK${NC}"
      
      # Read the test file
      echo -n "Reading test file... "
      if read_content=$(docker exec dockfuse cat "/mnt/s3bucket/$test_file"); then
        echo -e "${GREEN}OK${NC}"
        
        # Verify content
        if [ "$read_content" = "$test_content" ]; then
          echo -e "${GREEN}Content verification: PASSED${NC}"
        else
          echo -e "${RED}Content verification: FAILED${NC}"
          echo "Expected: $test_content"
          echo "Got: $read_content"
        fi
        
        # Delete the test file
        echo -n "Deleting test file... "
        if docker exec dockfuse rm "/mnt/s3bucket/$test_file"; then
          echo -e "${GREEN}OK${NC}"
        else
          echo -e "${RED}FAILED${NC}"
          echo "Could not delete test file. You may need to remove it manually."
        fi
      else
        echo -e "${RED}FAILED${NC}"
        echo "Could not read test file."
      fi
    else
      echo -e "${RED}FAILED${NC}"
      echo "Could not create test file. Check container logs for details."
    fi
  fi
fi

echo -e "\n${YELLOW}======================================"
echo "Test Complete"
echo -e "======================================${NC}"
echo "For more information, check the container logs:"
echo "docker logs dockfuse" 