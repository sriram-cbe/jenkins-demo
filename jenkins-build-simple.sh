#!/bin/bash

# Simple Jenkins Build Script - Minimal and Robust
# This version avoids potential hanging issues

set -e  # Exit on any error

echo "=== Jenkins Build Started ==="
echo "Timestamp: $(date)"

# Function to run commands with timeout
run_with_timeout() {
    local timeout_duration=$1
    shift
    local cmd="$@"
    
    echo "Running: $cmd"
    if timeout "$timeout_duration" bash -c "$cmd"; then
        echo "✅ Command completed successfully"
        return 0
    else
        echo "❌ Command failed or timed out after ${timeout_duration}s"
        return 1
    fi
}

# Check if we're in the right directory
if [ ! -f "gradlew" ]; then
    echo "❌ gradlew not found. Are you in the correct directory?"
    exit 1
fi

# Make gradlew executable
echo "Making gradlew executable..."
chmod +x gradlew

# Set up Java environment if needed
if [ -z "$JAVA_HOME" ]; then
    echo "⚠️  JAVA_HOME not set, trying to detect Java..."
    
    # Common Java locations
    for java_path in \
        "/usr/lib/jvm/java-17-openjdk-amd64" \
        "/usr/lib/jvm/java-17-openjdk" \
        "/usr/lib/jvm/temurin-17-jdk" \
        "/opt/java/openjdk" \
        "/usr/lib/jvm/default-java" \
        "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home" \
        "/System/Library/Frameworks/JavaVM.framework/Versions/Current"; do
        
        if [ -d "$java_path" ] && [ -x "$java_path/bin/java" ]; then
            export JAVA_HOME="$java_path"
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "✅ Found Java at: $JAVA_HOME"
            break
        fi
    done
    
    if [ -z "$JAVA_HOME" ]; then
        echo "❌ Could not find Java installation"
        echo "Please set JAVA_HOME or install Java 17"
        exit 1
    fi
fi

# Quick Java test (with timeout)
echo "Testing Java installation..."
if ! run_with_timeout 10 "java -version"; then
    echo "❌ Java test failed"
    exit 1
fi

# Clean build
echo "=== Cleaning previous builds ==="
if ! run_with_timeout 60 "./gradlew clean --no-daemon"; then
    echo "❌ Clean failed"
    exit 1
fi

# Compile
echo "=== Compiling ==="
if ! run_with_timeout 120 "./gradlew compileJava --no-daemon"; then
    echo "❌ Compilation failed"
    exit 1
fi

# Run tests
echo "=== Running Tests ==="
if ! run_with_timeout 300 "./gradlew test --no-daemon"; then
    echo "❌ Tests failed"
    exit 1
fi

# Build JAR (skip tests since we already ran them)
echo "=== Building JAR ==="
if ! run_with_timeout 120 "./gradlew build -x test --no-daemon"; then
    echo "❌ Build failed"
    exit 1
fi

# Verify build artifacts
echo "=== Verifying Build Artifacts ==="
if [ -f "build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar" ]; then
    echo "✅ JAR file created successfully"
    ls -la build/libs/
else
    echo "❌ Expected JAR file not found"
    exit 1
fi

echo "=== Build Completed Successfully ==="
echo "Timestamp: $(date)"
echo "Build artifacts are available in build/libs/"