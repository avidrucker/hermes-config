# Processing Large Issue Backlogs

## Problem
`gh issue list --limit 100 --json ...` returns ~50K+ chars of JSON that exceeds LLM context limits when injected directly.

## Solution: Tabular Output + Local Script

Use gh's `-q` (jq) formatter to produce compact tab-separated output, then process with `execute_code` (local Python).

### gh Command (tabular)
```bash
gh issue list --state open --limit 100 --json number,title,labels,createdAt \
  -q '.[] | "\(.number)\t\([.labels[].name]|join(","))\t\(.title)"'
```

### Processing Script (execute_code)
```python
from hermes_tools import terminal

result = terminal(command="gh issue list ... -q '...'", workdir=...)
issues_raw = result["output"].strip().split('\n')

issues = []
for line in issues_raw:
    num, labels_str, title = line.split('\t', 2)
    issues.append((int(num), title, labels_str.split(',')))

wt_result = terminal(command="git worktree list", workdir=...)
ps_result = terminal(command="npm run puzzle:status", workdir=...)

# Partition & rank in Python, print markdown tables
```

### Why This Works
- `execute_code` handles full output without LLM context pressure
- Pure logic stays in script; LLM only sees final summary tables
- Parallel fetches via multiple `terminal()` calls
