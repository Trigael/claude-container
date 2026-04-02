#!/bin/bash
set -e

# Show help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $(basename "$0") [project-path]"
    echo "Run Claude Code CLI in AUTO mode (all permission checks disabled)."
    echo ""
    echo "Options:"
    echo "  project-path    Path to mount as /workspace (default: current directory)"
    echo "  -h, --help      Show this help message"
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

# Check that the image exists
if ! docker image inspect claude-dev &> /dev/null 2>&1; then
    echo "Error: 'claude-dev' image not found. Run ./scripts/build.sh first." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${1:-$(pwd)}"

# Warn the user about auto mode
echo "=========================================="
echo "  WARNING: RUNNING IN AUTO MODE"
echo "  All permission checks are DISABLED."
echo "  Only use with TRUSTED code."
echo "=========================================="
echo ""

docker run -it --rm \
  --privileged \
  -v "$PROJECT_ROOT/auth":/home/claude/.claude \
  -v "$PROJECT_PATH":/workspace \
  claude-dev yolo-claude
