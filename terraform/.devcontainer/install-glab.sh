#!/usr/bin/env bash
# Install the latest GitLab CLI (glab) from the official GitLab releases
set -euo pipefail

arch=$(dpkg --print-architecture)
tag=$(curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases/permalink/latest" \
  | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
version=${tag#v}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/glab.deb" \
  "https://gitlab.com/gitlab-org/cli/-/releases/${tag}/downloads/glab_${version}_linux_${arch}.deb"
sudo apt-get install -y "$tmp/glab.deb"
