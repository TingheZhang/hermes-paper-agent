---
name: hermes-arxiv-agent-deploy
description: Use this skill inside a Hermes conversation when a user wants Hermes to deploy genggng/hermes-arxiv-agent end to end, including cloning the GitHub repo, installing Python dependencies, checking Feishu readiness, running `prepare_deploy.sh` to generate `cronjob_prompt.generated.txt`, and creating a daily cron job via `/cron add <prompt>`.
---

# Hermes Arxiv Agent Deploy

This skill is for deployment and maintenance of the GitHub repository `genggng/hermes-arxiv-agent`.

This skill is only meant to be used inside Hermes. Do not add Hermes installation checks or Hermes bootstrap guidance here.

Use it when the user wants any of the following:

- install the project from GitHub
- set up or repair the daily arXiv monitoring cron job
- initialize a new machine for this project
- re-create the cron prompt with the correct local path

The repository defaults to monitoring quantization-related papers. If the user wants a different research topic, update `search_keywords.txt` during deployment.

Do not assume the current local folder name matches the remote repository name. Treat the GitHub repository name `hermes-arxiv-agent` as canonical for clone and deployment instructions.

## Deployment Goal

Bring the user to a working state where:

1. Feishu/Lark gateway is configured.
2. The repo `git@github.com:genggng/hermes-arxiv-agent.git` is cloned locally with an SSH remote.
3. Python dependencies are installed.
4. `cronjob_prompt.generated.txt` exists and points to the real local project directory.
5. A Hermes cron job exists, points to the real local project directory, and delivers back to the Feishu/Lark chat instead of `local`.

Because this skill runs inside Hermes, Hermes itself is already present by assumption.
If Feishu is not configured, that is a deploy-time prerequisite to surface, not a reason to discuss Hermes installation.

## Required Workflow

Follow this order unless the user explicitly asks for a partial action.

### 1. Verify prerequisites

Check:

- Python 3 is available
- `pip` or `pip3` is available
- GitHub SSH authentication is available for `git@github.com`

If Feishu/Lark is not configured, direct the user to run:

```bash
hermes gateway setup
```

The cron job for this repository should be created from a Feishu/Lark Hermes conversation, not from a local CLI-only chat.
For this project, the intended delivery target is Feishu/Lark.

When creating or repairing the cron job, ensure its delivery is set to `feishu` rather than `local`.

### 2. Clone or locate the repository

Preferred default:

```bash
git clone git@github.com:genggng/hermes-arxiv-agent.git
cd hermes-arxiv-agent
```

If the repository already exists locally, reuse it instead of recloning.

If the existing repository uses an HTTPS `origin`, change it to:

```bash
git remote set-url origin git@github.com:genggng/hermes-arxiv-agent.git
```

The effective project directory must be captured as an absolute path and reused in later steps. Refer to it as `PROJECT_DIR`.

### 3. Install runtime dependencies

Run inside `PROJECT_DIR`:

```bash
pip install openpyxl requests pdfplumber
```

If the environment uses `pip3`, use that instead.

Also note the repository default search scope:

- the default query in `search_keywords.txt` targets quantization-related LLM papers
- if the user wants another topic, edit `search_keywords.txt` before the first scheduled run

### 4. Run the deployment preparation script

Run this script inside the checked-out repository:

```bash
bash prepare_deploy.sh
```

The script uses one deployment variable:

- `PROJECT_DIR`

If `PROJECT_DIR` is not supplied, the script uses its own directory as the project root. That is the preferred path, because it avoids manual mistakes after clone.

The script is responsible for:

- reading `cronjob_prompt.txt` as an immutable template
- generating `cronjob_prompt.generated.txt` with placeholder paths replaced
- removing the human-only path reminder from `cronjob_prompt.generated.txt`
- keeping the cron prompt aligned with the requirement to rebuild `viewer/papers_data.json` after Excel is updated
- normalizing the repository `origin` remote to SSH when it still points at the canonical HTTPS URL

If the user wants manual override, run:

```bash
PROJECT_DIR=/absolute/path/to/hermes-arxiv-agent bash prepare_deploy.sh
```

### 5. Understand the current path constraint

The repository code now resolves its own paths relative to the checked-out project directory, but the Hermes cron prompt still needs the real absolute checkout path.

This means:

- do not leave placeholder paths such as `/path/to/hermes-arxiv-agent`
- always finish cron prompt generation before creating the cron job

### 6. Use the generated cron prompt as the cron payload

After step 4:

- `cronjob_prompt.txt` remains the repository template
- `cronjob_prompt.generated.txt` contains the real project path and no longer contains the human-only path-replacement reminder

Use the full current contents of `cronjob_prompt.generated.txt` as the exact `<prompt>` payload for:

```text
/cron add <prompt>
```

Do not rewrite the prompt from memory. Read it from the patched file and use it directly.
This is a Hermes chat slash command, not a bash command.
Do not try to execute `/cron add` through `bash`, `sh`, or `subprocess`.

Verify the generated file now references paths under `PROJECT_DIR`, for example:

- `PROJECT_DIR/new_papers.json`
- `PROJECT_DIR/papers_record.xlsx`
- `PROJECT_DIR/monitor.py`

### 7. Create the cron job

Create the job inside the Feishu/Lark Hermes conversation using the standard slash-command form with the exact current contents of `cronjob_prompt.generated.txt`.

Delivery must be `feishu`, so the final cron output is pushed to Feishu/Lark rather than being saved only as `local`.

If the current job was previously created with delivery `local`, recreate it or edit it so the effective delivery target becomes `feishu`.

After creation, confirm:

- prompt contains the real absolute path
- the job is listed in `/cron list`
- the business instructions from `cronjob_prompt.txt` were preserved exactly in `cronjob_prompt.generated.txt`
- delivery is not `local`
- delivery is set to `feishu`

## Agent Behavior Rules

- Prefer automation over asking the user to hand-edit prompt text.
- Do not ask the user to rename their local directory.
- Keep the repository name `hermes-arxiv-agent` in clone instructions and user-facing descriptions.
- If local folder names differ, adapt by substituting the actual absolute path rather than forcing a rename.
- When reconfiguring cron, rerun `prepare_deploy.sh` and then reuse `cronjob_prompt.generated.txt`.
- Prefer `prepare_deploy.sh` over ad hoc manual edits, because it centralizes all known path fixes behind one variable.
- Do not paraphrase or simplify the substantive task instructions from `cronjob_prompt.txt`.
- Treat `cronjob_prompt.txt` as the template source of truth and `cronjob_prompt.generated.txt` as the deployable cron payload.
- Treat `/cron add` and `/cron list` as Hermes chat commands, not shell commands.
- Treat Feishu/Lark delivery as required for this project; set the cron delivery target to `feishu` and do not leave the job on `local`.
- Keep repository code path handling relative; do not reintroduce machine-specific absolute paths into tracked files.
- Prefer an SSH Git remote for this repository so scheduled publishing can push without HTTPS credential prompts.

## Path Handling Guidance

The remaining deployment-specific path lives in the Hermes cron prompt, not in the tracked Python code.

The correct approach is:

1. Determine `PROJECT_DIR` after clone or discovery.
2. Run `prepare_deploy.sh`.
3. Confirm that `cronjob_prompt.generated.txt` was created with the correct absolute project path.
4. Use the generated cron prompt file content directly when creating or updating cron.

If future code changes are allowed, recommend this improvement:

- keep code paths relative to the repository root
- keep deployment-specific absolute paths out of tracked files

## Expected User-Facing Outcome

After successful use of this skill, the user should only need Hermes for normal operations:

- view cron jobs
- rerun the job manually
- update keywords
- inspect generated Excel and viewer output

The user should not need to manually edit repository paths in prompt text.
