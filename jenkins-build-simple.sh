#!/bin/bash

# Simple Jenkins Build Script - Works with local Jenkins setup
set -e  # Exit on any error

echo "=== Jenkins Build Started ==="
echo "Timestamp: $(date)"

# Check if we're in the right directory
if [ ! -f "gradlew" ]; then
    echo "❌ gradlew not found. Are you in the correct directory?"
    exit 1
fi

# Make gradlew executable
echo "Making gradlew executable..."
chmod +x gradlew

# Simple Java setup - check if java is available
echo "Checking Java availability..."

if command -v java >/dev/null 2>&1; then
    echo "✅ Java command found"
    echo "Java version:"
    java -version
    
    # If JAVA_HOME is not set, try to set it from java command
    if [ -z "$JAVA_HOME" ]; then
        echo "JAVA_HOME not set, attempting to detect..."
        
        # Get java command path
        JAVA_CMD=$(which java)
        echo "Java command at: $JAVA_CMD"
        
        # Try to get JAVA_HOME from the java command path
        # Remove /bin/java to get JAVA_HOME
        POTENTIAL_JAVA_HOME=$(dirname $(dirname "$JAVA_CMD"))
        
        # Check if it's a valid JAVA_HOME
        if [ -d "$POTENTIAL_JAVA_HOME" ] && [ -x "$POTENTIAL_JAVA_HOME/bin/java" ]; then
            export JAVA_HOME="$POTENTIAL_JAVA_HOME"
            echo "✅ Set JAVA_HOME to: $JAVA_HOME"
        else
            echo "⚠️  Could not determine JAVA_HOME, but java command is available"
            echo "This might still work for Gradle"
        fi
    else
        echo "✅ JAVA_HOME already set: $JAVA_HOME"
    fi
    
    # Ensure java is in PATH
    if [ -n "$JAVA_HOME" ]; then
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
    
else
    echo "❌ Java not found in PATH"
    echo "Current PATH: $PATH"
    echo ""
    echo "Please install Java or set JAVA_HOME in Jenkins job configuration:"
    echo "Environment Variables:"
    echo "  JAVA_HOME = /path/to/your/java/installation"
    echo "  PATH = \$JAVA_HOME/bin:\$PATH"
    exit 1
fi

echo ""
echo "Environment:"
echo "JAVA_HOME: ${JAVA_HOME:-'Not set'}"
echo "PATH: $PATH"
echo ""

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
else
    echo "❌ Expected JAR file not found"
    echo "Contents of build/libs/:"
    ls -la build/libs/ 2>/dev/null || echo "build/libs/ directory not found"
    exit 1
fi

echo "=== Build Completed Successfully ==="
echo "Timestamp: $(date)"
echo "Build artifacts are available in build/libs/"