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

# Persist ~/.claude.json through the auth volume mount.
# Claude CLI stores account/auth state in ~/.claude.json (outside ~/.claude/),
# which is lost when the container is recreated. Symlink it into the mounted
# auth directory so it survives restarts.
CLAUDE_JSON="/home/claude/.claude.json"
CLAUDE_JSON_PERSIST="/home/claude/.claude/.claude.json"

if [ -d /home/claude/.claude ]; then
    if [ -f "$CLAUDE_JSON_PERSIST" ]; then
        # Use the persisted version from a previous run
        ln -sf "$CLAUDE_JSON_PERSIST" "$CLAUDE_JSON"
    elif [ -f "$CLAUDE_JSON" ] && [ ! -L "$CLAUDE_JSON" ]; then
        # First run: seed the mount with the image copy, then symlink
        cp "$CLAUDE_JSON" "$CLAUDE_JSON_PERSIST"
        ln -sf "$CLAUDE_JSON_PERSIST" "$CLAUDE_JSON"
    fi
fi

exec "$@"
