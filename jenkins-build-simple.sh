#!/bin/bash

# Simple Jenkins Build Script - Minimal and Robust
# This version avoids potential hanging issues

set -e  # Exit on any error

echo "=== Jenkins Build Started ==="
echo "Timestamp: $(date)"

# Function to run commands with timeout (macOS compatible)
run_with_timeout() {
    local timeout_duration=$1
    shift
    local cmd="$@"
    
    echo "Running: $cmd"
    
    # Check if timeout command exists (Linux)
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout_duration" bash -c "$cmd"; then
            echo "✅ Command completed successfully"
            return 0
        else
            echo "❌ Command failed or timed out after ${timeout_duration}s"
            return 1
        fi
    else
        # macOS fallback - no timeout, just run the command
        echo "(Running without timeout on macOS)"
        if bash -c "$cmd"; then
            echo "✅ Command completed successfully"
            return 0
        else
            echo "❌ Command failed"
            return 1
        fi
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
    
    # Try to use java_home command on macOS first
    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        echo "Detected macOS, using java_home command..."
        if DETECTED_JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null); then
            export JAVA_HOME="$DETECTED_JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "✅ Found Java 17 at: $JAVA_HOME"
        elif DETECTED_JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null); then
            export JAVA_HOME="$DETECTED_JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "✅ Found Java at: $JAVA_HOME"
        fi
    fi
    
    # If still not found, try common locations
    if [ -z "$JAVA_HOME" ]; then
        echo "Trying common Java installation paths..."
        for java_path in \
            "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home" \
            "/Library/Java/JavaVirtualMachines/adoptopenjdk-17.jdk/Contents/Home" \
            "/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home" \
            "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home" \
            "/usr/lib/jvm/java-17-openjdk-amd64" \
            "/usr/lib/jvm/java-17-openjdk" \
            "/usr/lib/jvm/temurin-17-jdk" \
            "/opt/java/openjdk" \
            "/usr/lib/jvm/default-java" \
            "/System/Library/Frameworks/JavaVM.framework/Versions/Current"; do
            
            if [ -d "$java_path" ] && [ -x "$java_path/bin/java" ]; then
                export JAVA_HOME="$java_path"
                export PATH="$JAVA_HOME/bin:$PATH"
                echo "✅ Found Java at: $JAVA_HOME"
                break
            fi
        done
    fi
    
    # If still not found, try to find any Java
    if [ -z "$JAVA_HOME" ]; then
        echo "Trying to find any available Java..."
        if command -v java >/dev/null 2>&1; then
            # Get Java home from java command
            JAVA_CMD=$(which java)
            echo "Java command found at: $JAVA_CMD"
            
            # On macOS, java might be a wrapper, try to get real path
            if [ -L "$JAVA_CMD" ]; then
                # Follow symlinks
                if command -v readlink >/dev/null 2>&1; then
                    REAL_JAVA=$(readlink "$JAVA_CMD" 2>/dev/null || echo "$JAVA_CMD")
                    echo "Symlink points to: $REAL_JAVA"
                else
                    REAL_JAVA="$JAVA_CMD"
                fi
            else
                REAL_JAVA="$JAVA_CMD"
            fi
            
            # Extract JAVA_HOME (remove /bin/java)
            DETECTED_JAVA_HOME=$(dirname $(dirname "$REAL_JAVA"))
            echo "Potential JAVA_HOME: $DETECTED_JAVA_HOME"
            
            # Validate the detected path
            if [ -d "$DETECTED_JAVA_HOME" ] && [ -x "$DETECTED_JAVA_HOME/bin/java" ]; then
                export JAVA_HOME="$DETECTED_JAVA_HOME"
                export PATH="$JAVA_HOME/bin:$PATH"
                echo "✅ Found Java at: $JAVA_HOME"
            else
                echo "⚠️  Detected path doesn't contain valid Java installation"
                # Try parent directory (sometimes needed on macOS)
                PARENT_DIR=$(dirname "$DETECTED_JAVA_HOME")
                if [ -d "$PARENT_DIR" ] && [ -x "$PARENT_DIR/bin/java" ]; then
                    export JAVA_HOME="$PARENT_DIR"
                    export PATH="$JAVA_HOME/bin:$PATH"
                    echo "✅ Found Java at parent directory: $JAVA_HOME"
                fi
            fi
        fi
    fi
    
    if [ -z "$JAVA_HOME" ]; then
        echo "❌ Could not find Java installation"
        echo ""
        echo "Available Java installations on this system:"
        if command -v /usr/libexec/java_home >/dev/null 2>&1; then
            /usr/libexec/java_home -V 2>&1 || echo "No Java installations found via java_home"
        fi
        
        echo ""
        echo "Please either:"
        echo "1. Install Java 17: brew install openjdk@17"
        echo "2. Set JAVA_HOME in Jenkins job configuration"
        echo "3. Configure JDK in Jenkins Global Tool Configuration"
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