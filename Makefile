.PHONY: build run test clean

# Variables
IMAGE_NAME = dockfuse
TAG = latest
CONTAINER_NAME = dockfuse-test

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME):$(TAG) ./src

# Run the container for testing
run:
	docker-compose up -d

# Stop and remove the container
stop:
	docker-compose down

# Run tests
test:
	cd tests && ./run_tests.sh

# Clean up
clean:
	docker-compose down -v
	docker rmi $(IMAGE_NAME):$(TAG)

# Show help
help:
	@echo "Available targets:"
	@echo "  build  - Build the Docker image"
	@echo "  run    - Run the container using docker-compose"
	@echo "  stop   - Stop and remove the container"
	@echo "  test   - Run the test suite"
	@echo "  clean  - Clean up containers and images"
	@echo "  help   - Show this help message"