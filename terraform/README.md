# Claude Code dev container

A VS Code dev container image with Claude Code, plus tooling for infrastructure work.
Other projects are opened in a container from this image with the `devc` shell function,
so they need no `.devcontainer/` folder of their own.

## What's included

- Ubuntu 26.04 (`ubuntu:26.04`) with the `common-utils` feature for the `vscode` user, zsh and Oh My Zsh
- Claude Code CLI (native install, in `~/.local/bin`) and VS Code extension
- AWS CLI, Terraform, GitLab CLI (`glab`)
- Utilities: `jq`, `yq` (mikefarah), `dig`, `nc`, `nmap`, `shellcheck`, `yamllint`, `pre-commit`
  (git hooks installed on the Mac also run in the container)
- VS Code Terraform extension, with format-on-save for `.tf` and `.tfvars`
- Pandoc with Typst, the `md2pdf` command and a matching Claude Code skill

## Prerequisites

- Docker Desktop (or OrbStack/Colima), running
- VS Code with the **Dev Containers** extension (`ms-vscode-remote.remote-containers`)
- The `code` command on your `PATH` (Command Palette → **Shell Command: Install 'code' command in PATH**)
- The Dev Containers CLI, used to build the image: `npm install -g @devcontainers/cli`

## Layout

| Path | Purpose |
| --- | --- |
| `.devcontainer/devcontainer.json` | Defines the image: base, features, extensions, settings |
| `.devcontainer/Dockerfile` | Ubuntu base, `glab` (via `install-glab.sh`), pandoc + Typst, Claude Code |
| `.devcontainer/md2pdf` | Markdown to PDF wrapper, installed as `/usr/local/bin/md2pdf` |
| `.devcontainer/md2pdf.lua`, `md2pdf.typst` | Pandoc filter and Typst template used by `md2pdf` |
| `.devcontainer/skills/` | Claude Code skills, copied into `~/.claude/skills` on container create |
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
| `~/.claude-devcontainer` | `/home/vscode/.claude` | read-write |
| `~/.aws` | `/home/vscode/.aws` | read-write |
| `~/.ssh` | `/home/vscode/.ssh` | read-only |

All containers share `~/.claude-devcontainer`: Claude Code's login, settings, plugins,
conversation history and memory. You log in once (run `claude`, then `/login`), and every
project and rebuild keeps that login. It's a normal folder on the Mac, so Time Machine backs it
up and Docker resets don't touch it. It's separate from the Mac's own `~/.claude`. It contains
the Claude login token in plain text, so `initializeCommand` creates it with mode `700`.

`~/.aws` and `~/.ssh` must exist on the host, or the container won't start.

## Markdown to PDF

```sh
md2pdf notes.md                 # writes notes.pdf next to it
md2pdf notes.md out.pdf --toc   # extra arguments go to pandoc
```

Markdown is read the way GitHub reads it (`commonmark_x`): alerts (`> [!NOTE]` etc.) become
coloured boxes, emoji shortcodes (`:rocket:`) and bare URLs work, and inline HTML such as
`<sub>`, `<mark>`, `<kbd>` and `<details>` keeps its meaning. Remote images are downloaded.

Defaults: A4, Noto Sans, left-aligned text. A `#` heading at the start (or the only one) becomes
the title, and relative links (to files in the repo) are shown as plain text. Emoji and symbols
are rendered in black and white with the Symbola font. Mermaid diagrams are drawn without a
browser by the merman Typst package (baked into the image; most diagram types, not every
Mermaid feature; an invalid diagram shows an error box). These are
set in `.devcontainer/md2pdf.typst` (template) and `md2pdf.lua` (pandoc filter).

The `md2pdf` skill tells Claude to use this command, so you can just ask Claude for a PDF of a
Markdown file.

## Installing missing tools

The `install-tool` skill lets Claude install a tool the image doesn't have when a task needs it.
Claude asks first, prefers Ubuntu packages, then pinned official release binaries (checksum
verified, into `~/.local/bin`), and never pipes unknown scripts into a shell. These installs are
temporary: they're gone after **Rebuild Container**. Claude logs each one in
`~/.claude/installed-tools.md` (on the Mac: `~/.claude-devcontainer/installed-tools.md`), so
tools you keep needing show up there as candidates for the Dockerfile.

## Skills

Skills in `.devcontainer/skills/` (`md2pdf`, `install-tool`) are built into the image and copied
into the shared `~/.claude/skills` folder each time a container is created.

## Applying changes

- **Changed the image** (`.devcontainer/`): rebuild the image, then run
  **Dev Containers: Rebuild Container** in each open project.
- **Changed `project/.devcontainer.json`** (for example, mounts): run
  **Dev Containers: Rebuild Container** in the project. Existing containers keep their old mounts until you do.
