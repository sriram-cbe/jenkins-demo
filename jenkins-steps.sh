#!/bin/bash

# Individual Jenkins Build Steps
# Use these as separate build steps in Jenkins to isolate issues

# Step 1: Environment Setup
setup_environment() {
    echo "=== Step 1: Environment Setup ==="
    
    # Make gradlew executable
    chmod +x gradlew
    
    # Check if Java is available
    if command -v java >/dev/null 2>&1; then
        echo "✅ Java command found"
        # Quick java version check with timeout
        timeout 5 java -version || echo "⚠️  Java version check timed out"
    else
        echo "❌ Java command not found"
        
        # Try to find and set JAVA_HOME
        for java_home in \
            "/usr/lib/jvm/java-17-openjdk-amd64" \
            "/usr/lib/jvm/java-17-openjdk" \
            "/usr/lib/jvm/temurin-17-jdk" \
            "/opt/java/openjdk"; do
            
            if [ -d "$java_home" ] && [ -x "$java_home/bin/java" ]; then
                export JAVA_HOME="$java_home"
                export PATH="$JAVA_HOME/bin:$PATH"
                echo "✅ Set JAVA_HOME to: $JAVA_HOME"
                break
            fi
        done
        
        if [ -z "$JAVA_HOME" ]; then
            echo "❌ Could not find Java. Please install Java 17 or set JAVA_HOME"
            exit 1
        fi
    fi
    
    echo "Environment setup completed"
}

# Step 2: Clean
clean_build() {
    echo "=== Step 2: Clean Build ==="
    ./gradlew clean --no-daemon --stacktrace
    echo "Clean completed"
}

# Step 3: Compile
compile_code() {
    echo "=== Step 3: Compile ==="
    ./gradlew compileJava --no-daemon --stacktrace
    echo "Compilation completed"
}

# Step 4: Test
run_tests() {
    echo "=== Step 4: Run Tests ==="
    ./gradlew test --no-daemon --stacktrace
    echo "Tests completed"
}

# Step 5: Build
build_jar() {
    echo "=== Step 5: Build JAR ==="
    ./gradlew build -x test --no-daemon --stacktrace
    echo "Build completed"
}

# Step 6: Verify
verify_artifacts() {
    echo "=== Step 6: Verify Artifacts ==="
    if [ -f "build/libs/jenkins-demo-0.0.1-SNAPSHOT.jar" ]; then
        echo "✅ JAR file created successfully"
        ls -la build/libs/
    else
        echo "❌ JAR file not found"
        exit 1
    fi
    echo "Verification completed"
}

# Main execution
case "$1" in
    "setup")
        setup_environment
        ;;
    "clean")
        clean_build
        ;;
    "compile")
        compile_code
        ;;
    "test")
        run_tests
        ;;
    "build")
        build_jar
        ;;
    "verify")
        verify_artifacts
        ;;
    "all")
        setup_environment
        clean_build
        compile_code
        run_tests
        build_jar
        verify_artifacts
        ;;
    *)
        echo "Usage: $0 {setup|clean|compile|test|build|verify|all}"
        echo ""
        echo "Individual steps:"
        echo "  setup   - Set up environment and check Java"
        echo "  clean   - Clean previous builds"
        echo "  compile - Compile the code"
        echo "  test    - Run tests"
        echo "  build   - Build JAR file"
        echo "  verify  - Verify build artifacts"
        echo "  all     - Run all steps"
        exit 1
        ;;
esac