# Makefile for Jenkins Demo Docker Application

# Variables
IMAGE_NAME = jenkins-demo
IMAGE_TAG = latest
CONTAINER_NAME = jenkins-demo-app
PORT = 8090

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "Jenkins Demo Docker Application"
	@echo "==============================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build targets
.PHONY: build
build: ## Build the Docker image
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "Build completed successfully!"

.PHONY: build-no-cache
build-no-cache: ## Build the Docker image without cache
	@echo "Building Docker image without cache..."
	docker build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "Build completed successfully!"

# Run targets
.PHONY: run
run: ## Run the application container
	@echo "Starting Jenkins Demo application..."
	@make stop 2>/dev/null || true
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):$(PORT) \
		$(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Application started at http://localhost:$(PORT)"
	@echo "Health check: http://localhost:$(PORT)/home/health"

.PHONY: run-it
run-it: ## Run the application container interactively
	@echo "Running Jenkins Demo application interactively..."
	docker run -it --rm \
		--name $(CONTAINER_NAME)-interactive \
		-p $(PORT):$(PORT) \
		$(IMAGE_NAME):$(IMAGE_TAG)

# Docker Compose targets
.PHONY: up
up: ## Start services using docker-compose
	@echo "Starting services with docker-compose..."
	docker-compose up -d
	@echo "Services started successfully!"

.PHONY: down
down: ## Stop services using docker-compose
	@echo "Stopping services with docker-compose..."
	docker-compose down
	@echo "Services stopped successfully!"

.PHONY: logs
logs: ## View docker-compose logs
	docker-compose logs -f

# Management targets
.PHONY: stop
stop: ## Stop the running container
	@echo "Stopping container..."
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@echo "Container stopped and removed"

.PHONY: restart
restart: stop run ## Restart the application container

.PHONY: shell
shell: ## Open a shell in the running container
	docker exec -it $(CONTAINER_NAME) sh

.PHONY: logs-container
logs-container: ## View container logs
	docker logs -f $(CONTAINER_NAME)

# Testing targets
.PHONY: test
test: ## Run tests in the application
	@echo "Running tests..."
	./gradlew test

.PHONY: test-docker
test-docker: ## Run tests inside Docker container
	@echo "Running tests in Docker..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) sh -c "./gradlew test"

.PHONY: health-check
health-check: ## Check application health
	@echo "Checking application health..."
	@curl -f http://localhost:$(PORT)/home/health || echo "Health check failed"

# Cleanup targets
.PHONY: clean
clean: ## Remove containers and images
	@echo "Cleaning up..."
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	@echo "Cleanup completed"

.PHONY: clean-all
clean-all: ## Remove all containers, images, and volumes
	@echo "Cleaning up everything..."
	@docker-compose down -v --rmi all 2>/dev/null || true
	@make clean
	@echo "Complete cleanup finished"

# Information targets
.PHONY: info
info: ## Show Docker image and container information
	@echo "Docker Images:"
	@docker images $(IMAGE_NAME) 2>/dev/null || echo "No images found"
	@echo ""
	@echo "Running Containers:"
	@docker ps --filter "name=$(CONTAINER_NAME)" 2>/dev/null || echo "No containers running"
	@echo ""
	@echo "Application URL: http://localhost:$(PORT)"
	@echo "Health Check: http://localhost:$(PORT)/home/health"

.PHONY: status
status: ## Show application status
	@echo "Application Status:"
	@echo "=================="
	@docker ps --filter "name=$(CONTAINER_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Container not running"
	@echo ""
	@echo "Health Check:"
	@curl -s http://localhost:$(PORT)/home/health 2>/dev/null && echo " ✓ Healthy" || echo " ✗ Unhealthy or not running"

# Development targets
.PHONY: dev
dev: build run ## Build and run for development
	@echo "Development environment ready!"
	@make health-check

.PHONY: quick-test
quick-test: ## Quick test cycle: build, run, test, stop
	@make build
	@make run
	@sleep 10
	@make health-check
	@make stop
	@echo "Quick test completed!"