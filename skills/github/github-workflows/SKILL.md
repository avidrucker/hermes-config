---
name: github-workflows
description: "Complete GitHub workflow: auth setup, issues, PRs, code review, repo management, and CI. Use when working with GitHub in any way — authenticating, creating/ triaging issues, opening/merging PRs, reviewing code, managing repos, or troubleshooting CI. Each section covers gh CLI first, then curl fallback."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [github, issues, pull-requests, code-review, ci, authentication, repos, workflow]
    related_skills: [codebase-inspection]
---

# GitHub Workflows

Complete guide for all GitHub operations — auth, issues, PRs, code review, repo management, and CI. Each section shows `gh` first, then `curl` fallback.

## Prerequisites Detection

```bash
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

---

## 1. Authentication

See `references/auth-setup.md` for full auth guide (HTTPS tokens, SSH keys, gh CLI login).

**Quick check:**
```bash
gh auth status 2>/dev/null || echo "not authenticated"
```

**Token-based login (headless):**
```bash
echo "<TOKEN>" | gh auth login --with-token
gh auth setup-git
```

**SSH key setup:** See `references/auth-setup.md`.

---

## 2. Issues — Create, Triage, Manage

### Viewing
```bash
gh issue list
gh issue list --state open --label "bug"
gh issue list --assignee @me
gh issue view 42
```

### Creating
```bash
gh issue create \
  --title "Login redirect ignores ?next= parameter" \
  --body "## Description\n..." \
  --label "bug,backend" \
  --assignee "username"
```

Templates: `templates/bug-report.md`, `templates/feature-request.md`.

### Managing (labels, assign, comment, close)
```bash
gh issue edit 42 --add-label "priority:high,bug"
gh issue edit 42 --add-assignee username
gh issue comment 42 --body "Investigated — root cause found."
gh issue close 42
gh issue reopen 42
```

### Triage Workflow
1. List untriaged: `gh issue list --label "needs-triage" --state open`
2. Read and categorize each issue
3. Apply labels and priority
4. Assign if owner is clear
5. Comment with triage notes

### Bulk Operations
```bash
gh issue list --label "wontfix" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"
```

### LCC.js-Specific Patterns
- **Multi-issue PM task:** Check wall clock first, create all issues, log as single PM task
- **Label hygiene:** `npm run claim` requires `area:*` label (not `area:uncategorized`)
- **Worktree claim flow:** `npm run claim -- <N> --as HONEYDEW` then `npm run close <N>`
- **Closing comments:** Post detailed summary table after pushing
- **Route rename pattern:** Update build script, add redirect, update tests
- **RULES.json reconciliation:** Preserve stable IDs, add status/relocated fields, fix collisions

---

## 3. Pull Requests — Branch, Commit, Open, CI, Merge

### Branch & Commit
```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b feat/add-user-authentication
# ... make changes ...
git add src/auth.py tests/test_auth.py
git commit -m "feat: add JWT-based user authentication"
git push -u origin HEAD
```

### Create PR
```bash
gh pr create \
  --title "feat: add JWT-based user authentication" \
  --body "## Summary\n...\n\nCloses #42"
```

Template: `templates/pr-body-feature.md`, `templates/pr-body-bugfix.md`.

### Monitor CI
```bash
gh pr checks
gh pr checks --watch
```

### Auto-Fix CI Loop
1. `gh pr checks` → identify failures
2. `gh run view <RUN_ID> --log-failed` → read logs
3. Fix code, commit, push
4. Re-check CI (up to 3 attempts)

### Merge
```bash
gh pr merge --squash --delete-branch
gh pr merge --auto --squash --delete-branch
```

### Full Workflow Example
```bash
git checkout main && git pull origin main
git checkout -b fix/login-redirect-bug
# ... make changes ...
git add src/auth/login.py tests/test_login.py
git commit -m "fix: correct redirect URL after login"
git push -u origin HEAD
gh pr create --title "fix: correct redirect URL" --body "Closes #42"
gh pr checks --watch
gh pr merge --squash --delete-branch
```

---

## 4. Code Review

### Review Local Changes (Pre-Push)
```bash
git diff main...HEAD --stat
git diff main...HEAD
```

Check for debug statements, secrets, merge conflict markers, large files.

### Review a PR on GitHub
```bash
gh pr view 123
gh pr diff 123
gh pr diff 123 --name-only
```

Check out PR locally:
```bash
git fetch origin pull/123/head:pr-123
git checkout pr-123
```

### Leave Comments
```bash
gh pr comment 123 --body "Overall looks good."
```

### Inline Comments
```bash
HEAD_SHA=$(gh pr view 123 --json headRefOid --jq '.headRefOid')
gh api repos/$OWNER/$REPO/pulls/123/comments \
  --method POST \
  -f body="Use parameterized queries." \
  -f path="src/auth/login.py" \
  -f commit_id="$HEAD_SHA" \
  -f line=45 \
  -f side="RIGHT"
```

### Formal Review (Approve / Request Changes)
```bash
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "See inline comments."
```

### Review Checklist
- **Correctness:** Edge cases, error paths, concurrency
- **Security:** No hardcoded secrets, input validation, no SQL injection/XSS
- **Code Quality:** Clear naming, DRY, single responsibility
- **Testing:** New code paths tested, happy + error cases
- **Performance:** No N+1 queries, appropriate caching
- **Documentation:** Public APIs documented, "why" comments

### End-to-End PR Review Recipe
1. `gh pr view N` — get metadata
2. `gh pr diff N --name-only` — scope of changes
3. `git fetch origin pull/N/head:pr-N && git checkout pr-N` — local checkout
4. `git diff main...HEAD` — full diff
5. Run tests/locally if applicable
6. Submit review with inline comments
7. `git checkout main && git branch -D pr-N` — cleanup

---

## 5. Repository Management

### Clone / Create / Fork
```bash
gh repo clone owner/repo-name
gh repo create my-project --public --clone
gh repo fork owner/repo-name --clone
```

### Repo Info & Settings
```bash
gh repo view owner/repo-name
gh repo edit --description "Updated" --visibility public
gh repo edit --enable-auto-merge
```

### Branch Protection
```bash
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  -d '{"required_status_checks":{"strict":true,"contexts":["ci/test"]},"required_pull_request_reviews":{"required_approving_review_count":1}}'
```

### Secrets (GitHub Actions)
```bash
gh secret set API_KEY --body "value"
gh secret list
gh secret delete API_KEY
```

### Releases
```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release list
```

### GitHub Actions
```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID>
```

### Gists
```bash
gh gist create script.py --public --desc "Useful script"
gh gist list
```

---

## Quick Reference Table

| Action | gh | curl endpoint |
|--------|-----|--------------|
| List issues | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| Create issue | `gh issue create` | `POST /repos/{o}/{r}/issues` |
| View PR | `gh pr view N` | `GET /repos/{o}/{r}/pulls/N` |
| Create PR | `gh pr create` | `POST /repos/{o}/{r}/pulls` |
| Merge PR | `gh pr merge` | `PUT /repos/{o}/{r}/pulls/N/merge` |
| List workflows | `gh workflow list` | `GET /repos/{o}/{r}/actions/workflows` |
| Rerun CI | `gh run rerun ID` | `POST /repos/{o}/{r}/actions/runs/ID/rerun` |
| Set secret | `gh secret set KEY` | `PUT /repos/{o}/{r}/actions/secrets/KEY` |
| Create release | `gh release create` | `POST /repos/{o}/{r}/releases` |

---

## @todo — generalize beyond lccjs

The main skill is generic GitHub operations. The lccjs-specific parts to extract/replace when porting:
- The "LCC.js-Specific Patterns" section (claim/worktree/closing-comment/RULES.json conventions).
- `references/pm-task-workflow.md` (contains `avidrucker/lccjs` issue URLs and an lccjs PM workflow).
