#!/usr/bin/env bash
set -euo pipefail

# Override this if needed. When left unchanged, the script uses its own location.
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")" && pwd)}"
EXPECTED_HTTPS_REMOTE="https://github.com/genggng/hermes-arxiv-agent.git"
EXPECTED_SSH_REMOTE="git@github.com:genggng/hermes-arxiv-agent.git"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: PROJECT_DIR does not exist: $PROJECT_DIR" >&2
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/monitor.py" ]]; then
  echo "ERROR: monitor.py not found under PROJECT_DIR: $PROJECT_DIR" >&2
  exit 1
fi

if [[ -d "$PROJECT_DIR/.git" ]]; then
  current_remote="$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$current_remote" == "$EXPECTED_HTTPS_REMOTE" || "$current_remote" == "https://github.com/genggng/hermes-arxiv-agent" ]]; then
    git -C "$PROJECT_DIR" remote set-url origin "$EXPECTED_SSH_REMOTE"
    echo "Updated git remote:"
    echo "- origin => $EXPECTED_SSH_REMOTE"
  fi
fi

export PROJECT_DIR

python3 - <<'PY'
import os
import re
from pathlib import Path

project_dir = Path(os.environ["PROJECT_DIR"]).resolve()
project_dir_str = str(project_dir)


root = project_dir

# cronjob prompt: generate from template, do not overwrite template
cron_template = root / "cronjob_prompt.txt"
cron_generated = root / "cronjob_prompt.generated.txt"
cron_text = cron_template.read_text(encoding="utf-8")
cron_text = re.sub(
    r"^【重要】.*(?:\r?\n)?",
    "",
    cron_text,
    count=1,
    flags=re.MULTILINE,
)
cron_text = cron_text.replace("/path/to/hermes-arxiv-agent", project_dir_str)
cron_generated.write_text(cron_text, encoding="utf-8")

print(f"Patched repository for PROJECT_DIR={project_dir_str}")
print("Updated files:")
print("- cronjob_prompt.generated.txt")
print("")
print("Next step inside Hermes chat:")
print("1. Read the full current contents of cronjob_prompt.generated.txt")
print("2. Send a Hermes slash command: /cron add <prompt>")
print("3. Do not try to run /cron add in bash or a system shell")
PY
