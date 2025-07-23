#!/bin/bash

# Build Docker image for causal inference workflow

echo "Building Docker image for causal inference workflow..."

# Build the Docker image
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t causal-inference:latest .

if [ $? -eq 0 ]; then
    echo "Docker image built successfully!"
    echo "Image name: causal-inference:latest"

    # Show image info
    docker images causal-inference:latest
else
    echo "Docker build failed!"
    exit 1
fi
