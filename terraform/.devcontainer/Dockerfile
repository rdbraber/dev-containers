FROM ubuntu:26.04

ENV LANG=C.UTF-8

# Replace the image's default "ubuntu" user (UID 1000) with vscode; the common-utils
# feature finishes setting the user up (shell, sudo, locale) after this Dockerfile.
RUN userdel -r ubuntu \
    && apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo xz-utils \
    && useradd -m -s /bin/bash -u 1000 vscode \
    && rm -rf /var/lib/apt/lists/*

COPY install-glab.sh /tmp/install-glab.sh
RUN bash /tmp/install-glab.sh && rm /tmp/install-glab.sh

# Pandoc with Typst for Markdown to PDF conversion; Symbola covers emoji and symbols
ARG TYPST_VERSION=0.15.1
RUN apt-get update && apt-get install -y --no-install-recommends \
      pandoc fonts-noto-core fonts-noto-mono fonts-symbola \
    && rm -rf /var/lib/apt/lists/* \
    && arch=$(uname -m) \
    && curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${arch}-unknown-linux-musl.tar.xz" \
      | tar -xJ --strip-components=1 -C /usr/local/bin "typst-${arch}-unknown-linux-musl/typst"

# Typst packages used by md2pdf.typst, fetched at build time so md2pdf works offline
ENV TYPST_PACKAGE_CACHE_PATH=/usr/local/share/typst/packages
RUN printf '#import "@preview/merman:0.5.0": mermaid\n#mermaid("flowchart LR\\n A --> B")\n' > /tmp/m.typ \
    && typst compile /tmp/m.typ /tmp/m.pdf && rm /tmp/m.typ /tmp/m.pdf

# Small DevOps utilities (jq and dig come with the common-utils feature) and pre-commit.
# pre-commit goes into a virtualenv at Homebrew's path: git hooks installed on the Mac start
# with #!/usr/local/opt/pre-commit/libexec/bin/python3, so the same hooks run here unchanged.
# (Ubuntu's pre-commit package would pull in a full gcc toolchain via nodeenv.)
ARG YQ_VERSION=4.54.1
ARG PRE_COMMIT_VERSION=4.7.0
RUN apt-get update && apt-get install -y --no-install-recommends \
      netcat-openbsd nmap shellcheck yamllint python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /usr/local/opt/pre-commit/libexec \
    && /usr/local/opt/pre-commit/libexec/bin/pip install --no-cache-dir "pre-commit==${PRE_COMMIT_VERSION}" \
    && ln -s /usr/local/opt/pre-commit/libexec/bin/pre-commit /usr/local/bin/pre-commit \
    && curl -fsSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_$(dpkg --print-architecture)" \
    && chmod +x /usr/local/bin/yq

# Claude Code, native install (no Node.js needed); installs into ~/.local
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash && rm -rf /home/vscode/.claude
USER root
ENV PATH=/home/vscode/.local/bin:$PATH

# md2pdf wrapper and Claude Code skills (copied into ~/.claude/skills by postCreateCommand)
COPY md2pdf /usr/local/bin/md2pdf
COPY md2pdf.lua md2pdf.typst /usr/local/share/md2pdf/
COPY skills/ /usr/local/share/claude-skills/
