#!/bin/bash

# Jenkins Java Setup Script
# Run this as the first build step to set up Java environment

echo "=== Jenkins Java Setup ==="

# Function to test Java installation
test_java() {
    local java_path="$1"
    if [ -x "$java_path/bin/java" ]; then
        echo "Testing Java at: $java_path"
        if timeout 5 "$java_path/bin/java" -version 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Check if JAVA_HOME is already set and working
if [ -n "$JAVA_HOME" ] && test_java "$JAVA_HOME"; then
    echo "✅ JAVA_HOME is already set and working: $JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    java -version
    exit 0
fi

echo "🔍 Searching for Java installations..."

# Method 1: Use macOS java_home utility
if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    echo "Using macOS java_home utility..."
    
    # Try to find Java 17 specifically
    if JAVA_17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null); then
        if test_java "$JAVA_17_HOME"; then
            export JAVA_HOME="$JAVA_17_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "✅ Found Java 17 at: $JAVA_HOME"
            java -version
            exit 0
        fi
    fi
    
    # Try to find any Java version
    if ANY_JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null); then
        if test_java "$ANY_JAVA_HOME"; then
            export JAVA_HOME="$ANY_JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "✅ Found Java at: $JAVA_HOME"
            java -version
            exit 0
        fi
    fi
    
    echo "Available Java versions on this system:"
    /usr/libexec/java_home -V 2>&1 || echo "No Java found via java_home"
fi

# Method 2: Search common installation paths
echo "Searching common installation paths..."
JAVA_PATHS=(
    "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
    "/Library/Java/JavaVirtualMachines/adoptopenjdk-17.jdk/Contents/Home"
    "/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home"
    "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
    "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
    "/opt/homebrew/opt/openjdk@17"
    "/opt/homebrew/opt/openjdk"
    "/usr/local/opt/openjdk@17"
    "/usr/local/opt/openjdk"
    "/usr/lib/jvm/java-17-openjdk-amd64"
    "/usr/lib/jvm/java-17-openjdk"
    "/usr/lib/jvm/temurin-17-jdk"
    "/opt/java/openjdk"
    "/usr/lib/jvm/default-java"
)

for java_path in "${JAVA_PATHS[@]}"; do
    if test_java "$java_path"; then
        export JAVA_HOME="$java_path"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Found Java at: $JAVA_HOME"
        java -version
        exit 0
    fi
done

# Method 3: Find Java from PATH
if command -v java >/dev/null 2>&1; then
    echo "Found java command in PATH, trying to determine JAVA_HOME..."
    JAVA_CMD=$(which java)
    echo "Java command location: $JAVA_CMD"
    
    # Try to resolve symlinks
    if command -v readlink >/dev/null 2>&1; then
        REAL_JAVA=$(readlink -f "$JAVA_CMD" 2>/dev/null || echo "$JAVA_CMD")
        echo "Real Java location: $REAL_JAVA"
        POTENTIAL_JAVA_HOME=$(dirname $(dirname "$REAL_JAVA"))
    else
        POTENTIAL_JAVA_HOME=$(dirname $(dirname "$JAVA_CMD"))
    fi
    
    if test_java "$POTENTIAL_JAVA_HOME"; then
        export JAVA_HOME="$POTENTIAL_JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "✅ Found Java at: $JAVA_HOME"
        java -version
        exit 0
    fi
fi

# If we get here, Java was not found
echo "❌ Could not find a working Java installation"
echo ""
echo "Please install Java 17 using one of these methods:"
echo ""
echo "Option 1 - Homebrew (recommended):"
echo "  brew install openjdk@17"
echo "  sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
echo ""
echo "Option 2 - Download from Eclipse Temurin:"
echo "  https://adoptium.net/temurin/releases/?version=17"
echo ""
echo "Option 3 - Set JAVA_HOME in Jenkins:"
echo "  1. Go to Jenkins job configuration"
echo "  2. Add environment variable: JAVA_HOME=/path/to/your/java"
echo ""
echo "Option 4 - Configure JDK in Jenkins Global Tools:"
echo "  1. Manage Jenkins → Global Tool Configuration"
echo "  2. Add JDK with name 'JDK17'"
echo "  3. Use Jenkinsfile with tools { jdk 'JDK17' }"

exit 1