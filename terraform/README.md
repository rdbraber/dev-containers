# Claude Code dev container

A VS Code dev container image with Claude Code, plus tooling for infrastructure work.
Other projects are opened in a container from this image with the `devc` shell function,
so they need no `.devcontainer/` folder of their own.

## What's included

- Ubuntu base image (`mcr.microsoft.com/devcontainers/base:ubuntu`)
- Claude Code CLI and VS Code extension
- Node.js, AWS CLI, Terraform, GitLab CLI (`glab`)
- VS Code Terraform extension, with format-on-save for `.tf` and `.tfvars`

## Prerequisites

- Docker Desktop (or OrbStack/Colima), running
- VS Code with the **Dev Containers** extension (`ms-vscode-remote.remote-containers`)
- The `code` command on your `PATH` (Command Palette → **Shell Command: Install 'code' command in PATH**)
- The Dev Containers CLI, used to build the image: `npm install -g @devcontainers/cli`

## Layout

| Path | Purpose |
| --- | --- |
| `.devcontainer/devcontainer.json` | Defines the image: base, features, extensions, settings |
| `.devcontainer/Dockerfile` | Base image plus `glab` (via `install-glab.sh`) |
| `project/.devcontainer.json` | Config `devc` uses to open other projects from the prebuilt image |

## Build the image

From this folder:

```sh
devcontainer build --workspace-folder . --image-name dev-containers:latest
```

Run this again after changing anything in `.devcontainer/`.

## Open a project with `devc`

Add this function to `~/.zshrc`:

```sh
function devc {
  local dir="$(cd "${1:-.}" && pwd)"
  local cfg="$HOME/git/dev-containers/terraform/project/.devcontainer.json"
  local json="{\"hostPath\":\"$dir\",\"configFile\":{\"\$mid\":1,\"path\":\"$cfg\",\"scheme\":\"file\"}}"
  local hex="$(printf '%s' "$json" | xxd -p | tr -d '\n')"
  code --folder-uri "vscode-remote://dev-container+${hex}/workspaces/$(basename "$dir")"
}
```

Then run `devc` (current directory) or `devc path/to/project`. VS Code opens the project in a
container. The project is mounted at `/workspaces/<project-name>`.

## Mounts

Mounts are applied when a container starts, not stored in the image. That is why both
`.devcontainer/devcontainer.json` and `project/.devcontainer.json` list them. Keep the two in sync.

| Host | Container | Mode |
| --- | --- | --- |
| Docker volume `claude-code-config` | `/home/vscode/.claude` | read-write |
| `~/.aws` | `/home/vscode/.aws` | read-write |
| `~/.ssh` | `/home/vscode/.ssh` | read-only |

All containers share the `claude-code-config` volume. You log in to Claude Code once
(run `claude`, then `/login`), and every project and rebuild keeps that login.

`~/.aws` and `~/.ssh` must exist on the host, or the container won't start.

## Applying changes

- **Changed the image** (`.devcontainer/`): rebuild the image, then run
  **Dev Containers: Rebuild Container** in each open project.
- **Changed `project/.devcontainer.json`** (for example, mounts): run
  **Dev Containers: Rebuild Container** in the project. Existing containers keep their old mounts until you do.
