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

# Claude Code, native install (no Node.js needed); installs into ~/.local
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash && rm -rf /home/vscode/.claude
USER root
ENV PATH=/home/vscode/.local/bin:$PATH

# md2pdf wrapper and Claude Code skills (copied into ~/.claude/skills by postCreateCommand)
COPY md2pdf /usr/local/bin/md2pdf
COPY md2pdf.lua md2pdf.typst /usr/local/share/md2pdf/
COPY skills/ /usr/local/share/claude-skills/
