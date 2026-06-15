# GitHub Authentication Setup

## Detection Flow
```bash
git --version
gh --version 2>/dev/null || echo "gh not installed"
gh auth status 2>/dev/null || echo "gh not authenticated"
```

**Decision tree:**
1. `gh auth status` shows authenticated → use `gh` for everything
2. `gh` installed but not authenticated → use "gh auth" method
3. `gh` not installed → use "git-only" method

## Method 1: Git-Only (No gh, No sudo)

### HTTPS with Personal Access Token
1. Create token at https://github.com/settings/tokens (scopes: `repo`, `workflow`, `read:org`)
2. `git config --global credential.helper store`
3. Test: `git ls-remote https://github.com/<user>/<repo>.git`
4. Set identity: `git config --global user.name "Name"` / `git config --global user.email "email"`

### SSH Key Authentication
1. `ssh-keygen -t ed25519 -C "email" -f ~/.ssh/id_ed25519 -N ""`
2. Add public key at https://github.com/settings/keys
3. `ssh -T git@github.com`
4. `git config --global url."git@github.com:".insteadOf "https://github.com/"`

## Method 2: gh CLI Authentication
```bash
# Interactive (desktop)
gh auth login

# Token-based (headless)
echo "<TOKEN>" | gh auth login --with-token
gh auth setup-git
```

## API Access Without gh
```bash
export GITHUB_TOKEN="<token>"
curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

Extract token from git credentials:
```bash
grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|'
```

## Troubleshooting
| Problem | Solution |
|---------|----------|
| `git push` asks for password | Use PAT as password, or switch to SSH |
| `Permission denied` | Token may lack `repo` scope |
| `Authentication failed` | Cached credentials stale — re-authenticate |
| SSH port 22 refused | Use SSH over HTTPS port 443 in `~/.ssh/config` |
| `gh: command not found` | Use git-only method above |
