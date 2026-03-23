#!/bin/bash

# Jenkins Build Script for Java Spring Boot Application
# This script ensures Java is available and runs the build

set -e  # Exit on any error

echo "🚀 Starting Jenkins Build for Jenkins Demo Application"
echo "=================================================="

# Function to print colored output
print_info() {
    echo "ℹ️  [INFO] $1"
}

print_success() {
    echo "✅ [SUCCESS] $1"
}

print_error() {
    echo "❌ [ERROR] $1"
}

print_warning() {
    echo "⚠️  [WARNING] $1"
}

# Check if JAVA_HOME is set
if [ -z "$JAVA_HOME" ]; then
    print_warning "JAVA_HOME is not set. Attempting to find Java..."
    
    # Try to find Java in common locations
    POSSIBLE_JAVA_HOMES=(
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/java-17-openjdk-amd64"
        "/usr/lib/jvm/temurin-17-jdk"
        "/opt/java/openjdk"
        "/usr/lib/jvm/default-java"
        "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
        "/System/Library/Frameworks/JavaVM.framework/Versions/Current"
    )
    
    for java_home in "${POSSIBLE_JAVA_HOMES[@]}"; do
        if [ -d "$java_home" ] && [ -x "$java_home/bin/java" ]; then
            export JAVA_HOME="$java_home"
            print_info "Found Java at: $JAVA_HOME"
            break
        fi
    done
    
    # If still not found, try using java command directly
    if [ -z "$JAVA_HOME" ]; then
        if command -v java >/dev/null 2>&1; then
            # Get Java home from java command
            JAVA_PATH=$(which java)
            JAVA_HOME=$(dirname $(dirname $(readlink -f $JAVA_PATH 2>/dev/null || echo $JAVA_PATH)))
            export JAVA_HOME
            print_info "Detected Java at: $JAVA_HOME"
        else
            print_error "Java not found! Please install Java 17 or set JAVA_HOME"
            exit 1
        fi
    fi
fi

# Set PATH to include Java
export PATH="$JAVA_HOME/bin:$PATH"

# Verify Java installation
print_info "Verifying Java installation..."
if ! command -v java >/dev/null 2>&1; then
    print_error "Java command not found in PATH"
    exit 1
fi

# Display environment information
echo ""
echo "Environment Information:"
echo "======================="
echo "JAVA_HOME: $JAVA_HOME"
echo "PATH: $PATH"
echo "Java Version:"

# Test java -version with timeout to prevent hanging
if timeout 10 java -version 2>&1; then
    print_success "Java version check completed"
else
    print_error "Java version check failed or timed out"
    
    # Try alternative approach
    print_info "Attempting alternative Java detection..."
    if [ -x "$JAVA_HOME/bin/java" ]; then
        print_info "Java executable found at: $JAVA_HOME/bin/java"
        if timeout 10 "$JAVA_HOME/bin/java" -version 2>&1; then
            print_success "Alternative Java version check completed"
        else
            print_error "Java is not responding properly. Please check your Java installation."
            exit 1
        fi
    else
        print_error "Java executable not found or not executable"
        exit 1
    fi
fi
echo ""

# Make gradlew executable
print_info "Making gradlew executable..."
chmod +x gradlew

# Display Gradle version
print_info "Checking Gradle version..."
if timeout 30 ./gradlew --version 2>&1; then
    print_success "Gradle version check completed"
else
    print_warning "Gradle version check failed or timed out, but continuing with build..."
fi

# Clean previous builds
print_info "Cleaning previous builds..."
./gradlew clean

# Compile the application
print_info "Compiling the application..."
./gradlew compileJava

# Run tests
print_info "Running tests..."
./gradlew test

# Build the application
print_info "Building the application..."
./gradlew build -x test  # Skip tests since we already ran them

# Display build results
print_info "Build completed successfully!"
echo ""
echo "Build Artifacts:"
echo "==============="
ls -la build/libs/

# Optional: Run a quick smoke test
if [ -f "build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar" ]; then
    print_success "JAR file created successfully: build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar"
    
    # Quick validation that the JAR is not corrupted
    if jar tf build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar >/dev/null 2>&1; then
        print_success "JAR file integrity check passed"
    else
        print_error "JAR file appears to be corrupted"
        exit 1
    fi
else
    print_error "Expected JAR file not found"
    exit 1
fi

print_success "Jenkins build completed successfully! 🎉"