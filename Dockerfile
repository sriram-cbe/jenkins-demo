# Multi-stage build for Java Spring Boot application

# Stage 1: Build stage
FROM gradle:8.5-jdk17 AS build

# Set working directory
WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradle/ gradle/
COPY gradlew .
COPY gradlew.bat .
COPY build.gradle .
COPY settings.gradle .

# Copy source code
COPY src/ src/

# Make gradlew executable
RUN chmod +x gradlew

# Build the application (skip tests for faster builds, run them separately if needed)
RUN ./gradlew build -x test --no-daemon

# Stage 2: Runtime stage
FROM eclipse-temurin:17-jre AS runtime

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -s /bin/sh -m appuser

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8090/home/health || exit 1

# Set JVM options for containerized environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]