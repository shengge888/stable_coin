#!/usr/bin/env bash
set -euo pipefail

# This script:
# 1) runs stablecoin_tracker.py (writes/updates stablecoin.xlsx)
# 2) commits stablecoin.xlsx into this repo root
# 3) pushes via HTTPS using env var GITHUB_TOKEN
#
# Required env:
#   GITHUB_TOKEN  - GitHub token with write access to shengge888/stable_coin
# Optional env:
#   GIT_USER_NAME, GIT_USER_EMAIL

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="/home/ubuntu/.openclaw/multi_workspace/planb"
TRACKER_PY="$WORK_DIR/stablecoin_tracker.py"
REQS_TXT="$WORK_DIR/requirements_stablecoin.txt"
XLSX_OUT="$REPO_DIR/stablecoin.xlsx"

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

cd "$REPO_DIR"

# Ensure python venv for dependencies
if [ ! -d "$REPO_DIR/.venv" ]; then
  python3 -m venv "$REPO_DIR/.venv"
fi
# shellcheck disable=SC1091
source "$REPO_DIR/.venv/bin/activate"
pip -q install -r "$REQS_TXT"

# Run tracker, output xlsx into repo root
python "$TRACKER_PY" --out "$XLSX_OUT"

# Commit & push if changed
if [ -n "$(git status --porcelain -- stablecoin.xlsx .gitignore 2>/dev/null)" ]; then
  git add stablecoin.xlsx .gitignore

  GIT_USER_NAME="${GIT_USER_NAME:-stablecoin-bot}"
  GIT_USER_EMAIL="${GIT_USER_EMAIL:-stablecoin-bot@local}"
  git -c user.name="$GIT_USER_NAME" -c user.email="$GIT_USER_EMAIL" commit -m "Update stablecoin snapshot $(date +%Y%m%d)" || true

  # Push using token without storing it in git config
  git push "https://x-access-token:${GITHUB_TOKEN}@github.com/shengge888/stable_coin.git" HEAD:master
fi
