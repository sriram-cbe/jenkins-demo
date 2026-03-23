#!/bin/bash

# Build script for Jenkins Demo Docker application
set -e

echo "🐳 Building Jenkins Demo Docker Application"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    echo "Please start Docker Desktop or Docker daemon"
    exit 1
fi

print_status "Docker is available and running"

# Build the Docker image
print_status "Building Docker image..."
if docker build -t jenkins-demo:latest .; then
    print_success "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Show image information
print_status "Image information:"
docker images jenkins-demo:latest

# Optional: Run tests in Docker
read -p "Do you want to run tests in Docker? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Running tests in Docker container..."
    if docker run --rm jenkins-demo:latest sh -c "./gradlew test"; then
        print_success "Tests passed successfully"
    else
        print_warning "Some tests failed, but image was built"
    fi
fi

# Optional: Start the application
read -p "Do you want to start the application now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting Jenkins Demo application..."
    
    # Stop any existing container
    docker stop jenkins-demo-app 2>/dev/null || true
    docker rm jenkins-demo-app 2>/dev/null || true
    
    # Start new container
    if docker run -d --name jenkins-demo-app -p 8090:8090 jenkins-demo:latest; then
        print_success "Application started successfully"
        print_status "Application is running at: http://localhost:8090"
        print_status "Health check endpoint: http://localhost:8090/home/health"
        
        # Wait a moment for the application to start
        sleep 5
        
        # Test the health endpoint
        if command -v curl &> /dev/null; then
            print_status "Testing health endpoint..."
            if curl -f http://localhost:8090/home/health; then
                echo
                print_success "Health check passed! Application is ready."
            else
                echo
                print_warning "Health check failed. Application might still be starting up."
            fi
        fi
        
        echo
        print_status "To view logs: docker logs -f jenkins-demo-app"
        print_status "To stop: docker stop jenkins-demo-app"
    else
        print_error "Failed to start application container"
        exit 1
    fi
fi

print_success "Build process completed!"
echo
echo "Next steps:"
echo "1. Test the application: curl http://localhost:8090/home/health"
echo "2. View logs: docker logs -f jenkins-demo-app"
echo "3. Stop the app: docker stop jenkins-demo-app"
echo "4. Use docker-compose: docker-compose up -d"