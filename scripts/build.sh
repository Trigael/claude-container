#!/bin/bash
set -e

# Show help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $(basename "$0")"
    echo "Build the claude-dev Docker image."
    exit 0
fi

# Check Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH" >&2
    exit 1
fi
if ! docker info &> /dev/null 2>&1; then
    echo "Error: Docker daemon is not running" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

docker build -t claude-dev "$PROJECT_ROOT"
