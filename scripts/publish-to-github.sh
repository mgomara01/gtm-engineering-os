#!/usr/bin/env bash
set -euo pipefail
repo_url="${1:-https://github.com/mgomara01/gtm-engineering-os.git}"
git remote remove origin 2>/dev/null || true
git remote add origin "$repo_url"
git push --set-upstream origin main
