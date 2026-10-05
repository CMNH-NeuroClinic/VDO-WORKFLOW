#!/bin/bash
# Installs browser-use/video-use as a Claude Code skill in cloud sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

VU_DIR="$HOME/Developer/video-use"

if [ -d "$VU_DIR/.git" ]; then
  git -C "$VU_DIR" pull --ff-only --quiet || true
else
  mkdir -p "$HOME/Developer"
  git clone --depth 1 --quiet https://github.com/browser-use/video-use "$VU_DIR"
fi

if ! command -v ffmpeg >/dev/null || ! command -v ffprobe >/dev/null; then
  apt-get update -qq && apt-get install -y -qq ffmpeg
fi

if command -v uv >/dev/null; then
  (cd "$VU_DIR" && uv sync --quiet)
  PY="$VU_DIR/.venv/bin/python"
else
  pip install --quiet -e "$VU_DIR"
  PY="python3"
fi

mkdir -p "$HOME/.claude/skills"
ln -sfn "$VU_DIR" "$HOME/.claude/skills/video-use"

# Helpers are called as `python helpers/...`; put the venv's python first on PATH.
if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -d "$VU_DIR/.venv/bin" ]; then
  echo "export PATH=\"$VU_DIR/.venv/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

"$PY" "$VU_DIR/helpers/timeline_view.py" --help >/dev/null

if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
  echo "video-use: ELEVENLABS_API_KEY is not set; add it in the environment settings to enable transcription." >&2
fi
