#!/bin/bash
set -e

# Start Docker daemon in the background (Docker-in-Docker)
if [ "${SKIP_DOCKER:-0}" = "1" ]; then
    echo "Docker daemon skipped (SKIP_DOCKER=1)."
else
    sudo dockerd --host=unix:///var/run/docker.sock --storage-driver=overlay2 > /tmp/dockerd.log 2>&1 &

    # Wait for Docker daemon to be ready
    echo "Waiting for Docker daemon..."
    timeout=30
    until docker info >/dev/null 2>&1; do
        timeout=$((timeout - 1))
        if [ "$timeout" -le 0 ]; then
            echo "Error: Docker daemon failed to start" >&2
            echo "Check logs: cat /tmp/dockerd.log" >&2
            exit 1
        fi
        sleep 1
    done
    echo "Docker daemon ready."
fi

# Ensure correct ownership of mounted .claude auth directory
if [ -d /home/claude/.claude ]; then
    sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
fi

exec "$@"
