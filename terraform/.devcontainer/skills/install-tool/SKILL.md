---
name: install-tool
description: Install a missing command-line tool in this dev container. Use when a command is not found, or when a task needs a CLI tool (for example kubectl, helm, terraform-docs, trivy) that isn't installed.
---

# Install a missing tool in the dev container

You are running in an Ubuntu dev container as the `vscode` user, with passwordless `sudo`.
Anything installed this way lives only in this container and is gone after a rebuild.

## Before installing

1. Check it really is missing: `command -v <tool>`. Also check whether an installed tool already
   covers the task (for example `jq`/`yq`, `dig`, `nc`, `nmap`, `shellcheck`, `yamllint`,
   `pre-commit`, `aws`, `terraform`, `terragrunt`, `tflint`, `gh`, `glab` are in the image).
2. Tell the user which tool you want to install, why, and how (package or download URL). Wait
   for them to agree before installing.

## How to install, in order of preference

1. **Ubuntu package**, when the packaged version is recent enough for the task:
   `sudo apt-get update && sudo apt-get install -y --no-install-recommends <package>`
   (the image removes the apt lists, so `apt-get update` is always needed first).
2. **Official release binary** from the project's own GitHub releases or download site:
   - Pick a specific version, not a `latest` redirect, and use the right architecture
     (`dpkg --print-architecture` gives `amd64`/`arm64`; `uname -m` gives `x86_64`/`aarch64`).
   - Verify the checksum when the release publishes one (`sha256sum -c`).
   - Install into `~/.local/bin` (already on `PATH`) with `chmod +x`; no `sudo` needed.
3. **Python tools**: `python3 -m venv ~/.local/share/venvs/<tool>`, `pip install` into it, then
   `ln -s ~/.local/share/venvs/<tool>/bin/<tool> ~/.local/bin/<tool>`.
4. **Node.js tools**: the image has no Node.js. Ask the user before installing it.

Never pipe a script from an unknown source into a shell (`curl ... | bash`). Only use install
scripts published by the tool's own project, and say so when you do.

## After installing

1. Run `<tool> --version` to confirm it works.
2. Append one line to `~/.claude/installed-tools.md` (this file survives rebuilds and is shared
   by all project containers), creating it with a short header if it doesn't exist:
   `- YYYY-MM-DD <tool> <version> via <apt|binary|venv> in <project folder name>`
3. Remind the user this install is temporary. If `~/.claude/installed-tools.md` shows the same
   tool installed before, suggest adding it to the image permanently (the
   `.devcontainer/Dockerfile` in the user's `dev-containers` repo) instead.
