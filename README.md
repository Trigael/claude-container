# docker-claude-web-dev

A Docker-based development environment for running the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) in isolated containers. It packages Ubuntu 24.04 with Node.js 22, Python 3, and a full Docker engine (Docker-in-Docker) so agents can develop and containerize web applications in a sandboxed environment.

## Prerequisites

- **Docker** (with the Docker daemon running)
- **Git**

## Quick Start

Build the Docker image:

```bash
./scripts/build.sh
```

## Usage

All run modes mount your project directory into `/workspace` inside the container. They default to the current working directory when no path is given.

### Interactive Claude

```bash
./scripts/claude.sh [project-path]
```

Launches the Claude Code CLI in interactive mode. You will be prompted for confirmation before Claude executes any action.

### Auto / Yolo Mode

```bash
./scripts/claude-auto.sh [project-path]
```

Launches Claude with the `--dangerously-skip-permissions` flag. This skips **all** permission prompts -- Claude can execute any action without confirmation.

> **Warning:** Only use auto mode with code you fully trust. See the Security Model section below.

### Shell

```bash
./scripts/shell.sh [project-path]
```

Opens an interactive bash shell inside the container for manual exploration.

### Docker Compose

```bash
# Interactive session
docker compose run --rm claude claude

# Auto mode
docker compose run --rm claude yolo-claude

# Mount a specific project
PROJECT_PATH=/path/to/project docker compose run --rm claude claude

# Safe mode (no Docker access inside container)
docker compose -f docker-compose.safe.yml run --rm claude claude
```

## Security Model

### Docker-in-Docker Isolation

This environment uses **true Docker-in-Docker**: a Docker daemon runs inside the container. Any containers the agent creates are **nested** within the outer container, not siblings on your host. This means:

- The agent **cannot** access your host's Docker daemon.
- The agent **cannot** mount your host filesystem via Docker.
- Nested containers are destroyed when the outer container exits.
- Mistakes and experiments stay fully contained.

The `--privileged` flag is required to allow the nested Docker daemon to manage cgroups and namespaces. This grants elevated kernel capabilities **inside the container** but does not expose the host's Docker daemon.

### Auto Mode

The `--dangerously-skip-permissions` flag disables Claude's built-in safety prompts. Inside the DinD environment this is relatively safe — the agent has full control over the container, but cannot escape to the host. This is the intended use case: a sandboxed environment where the agent can work freely.

### Safe Mode (No Docker)

Use `docker-compose.safe.yml` or set `SKIP_DOCKER=1` to run without Docker capabilities inside the container. The agent can still write code and run tests, but cannot build or run containers. Useful for code-only tasks on untrusted repositories.

### Sudo Access

The `claude` user has restricted sudo access for:
- `dockerd` — starting the nested Docker daemon
- `groupmod` — fixing group IDs at startup
- `chown` — fixing file ownership on mounted volumes

## Architecture

| File / Directory | Purpose |
|---|---|
| `Dockerfile` | Ubuntu 24.04 image with Node.js 22, Python 3, full Docker engine, and Claude CLI. |
| `entrypoint.sh` | Starts the nested Docker daemon and fixes auth directory ownership. |
| `scripts/` | Host-side convenience scripts. These run on the host, not inside the container. |
| `auth/` | Mounted as `/home/claude/.claude` to persist auth tokens. Gitignored. |
| `docker-compose.yml` | Standard DinD setup with `--privileged`. |
| `docker-compose.safe.yml` | No-Docker mode without `--privileged`. |

## Notes

- `scripts/` is in `.dockerignore` because the scripts only run on the host.
- Auth tokens in `auth/` are gitignored. Never commit credentials.
- Set `SKIP_DOCKER=1` env var to skip Docker daemon startup inside the container.
