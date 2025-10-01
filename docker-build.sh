#!/bin/bash

# Docker build and run script for DeviceStatus application

echo "Building Docker image for DeviceStatus application..."

# Build the Docker image
docker build -t devicestatus-app:latest .

if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
    
    echo "Running container..."
    # Run the container with environment variables
    docker run -d \
        --name devicestatus-container \
        -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=prod \
        -e DB_URL=jdbc:postgresql://host.docker.internal:5432/localdms \
        -e DB_USERNAME=postgres \
        -e DB_PASSWORD=hello@1234 \
        devicestatus-app:latest
    
    if [ $? -eq 0 ]; then
        echo "✅ Container started successfully!"
        echo "Application is running at: http://localhost:8080"
        echo "Health check: http://localhost:8080/actuator/health"
        echo ""
        echo "To view logs: docker logs devicestatus-container"
        echo "To stop container: docker stop devicestatus-container"
        echo "To remove container: docker rm devicestatus-container"
    else
        echo "❌ Failed to start container"
    fi
else
    echo "❌ Docker build failed"
fi
