#!/bin/bash

# Jenkins Build Script - macOS Optimized
# Specifically designed for macOS Jenkins agents

set -e  # Exit on any error

echo "=== Jenkins Build Started (macOS) ==="
echo "Timestamp: $(date)"

# Check if we're in the right directory
if [ ! -f "gradlew" ]; then
    echo "❌ gradlew not found. Are you in the correct directory?"
    exit 1
fi

# Make gradlew executable
echo "Making gradlew executable..."
chmod +x gradlew

# Set up Java environment for macOS
echo "Setting up Java environment for macOS..."

# Method 1: Try java_home utility (macOS specific)
if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    echo "Using macOS java_home utility..."
    
    # Try Java 17 first
    if JAVA_17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null); then
        export JAVA_HOME="$JAVA_17_HOME"
        echo "✅ Found Java 17 at: $JAVA_HOME"
    # Try Java 11
    elif JAVA_11_HOME=$(/usr/libexec/java_home -v 11 2>/dev/null); then
        export JAVA_HOME="$JAVA_11_HOME"
        echo "✅ Found Java 11 at: $JAVA_HOME"
    # Try any Java
    elif ANY_JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null); then
        export JAVA_HOME="$ANY_JAVA_HOME"
        echo "✅ Found Java at: $JAVA_HOME"
    fi
fi

# Method 2: Check if JAVA_HOME is set and valid
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    echo "✅ Using JAVA_HOME: $JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
else
    echo "❌ No valid Java installation found"
    echo ""
    echo "Available Java installations:"
    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        /usr/libexec/java_home -V 2>&1 || echo "No Java found"
    fi
    echo ""
    echo "Please install Java:"
    echo "  brew install openjdk@17"
    echo "  sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
    exit 1
fi

# Test Java
echo "Testing Java installation..."
echo "JAVA_HOME: $JAVA_HOME"
java -version

# Clean build
echo "=== Cleaning previous builds ==="
./gradlew clean --no-daemon --stacktrace

# Compile
echo "=== Compiling ==="
./gradlew compileJava --no-daemon --stacktrace

# Run tests
echo "=== Running Tests ==="
./gradlew test --no-daemon --stacktrace

# Build JAR (skip tests since we already ran them)
echo "=== Building JAR ==="
./gradlew build -x test --no-daemon --stacktrace

# Verify build artifacts
echo "=== Verifying Build Artifacts ==="
if [ -f "build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar" ]; then
    echo "✅ JAR file created successfully"
    ls -la build/libs/
    
    # Quick JAR validation
    if jar tf build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar >/dev/null 2>&1; then
        echo "✅ JAR file integrity check passed"
    else
        echo "⚠️  JAR file might be corrupted"
    fi
else
    echo "❌ Expected JAR file not found"
    echo "Contents of build/libs/:"
    ls -la build/libs/ || echo "build/libs/ directory not found"
    exit 1
fi

echo "=== Build Completed Successfully ==="
echo "Timestamp: $(date)"
echo ""
echo "Build Summary:"
echo "- Java Version: $(java -version 2>&1 | head -1)"
echo "- JAR Location: build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar"
echo "- JAR Size: $(ls -lh build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar | awk '{print $5}')"