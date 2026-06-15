---
name: debugging
description: "Debug Node.js, Python, and general bugs systematically. Covers node inspect, pdb, debugpy, post-mortem debugging, heap/CPU profiling, the 4-phase systematic debugging methodology, and common pitfalls. Use when a test fails, production crashes, behavior is unexpected, or performance problems need investigation."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [debugging, nodejs, python, pdb, debugpy, node-inspect, systematic, root-cause, breakpoints, dap]
    related_skills: [test-driven-development, plan]
---

# Debugging

Debug Node.js, Python, and general bugs systematically. Three sub-areas:
1. **Systematic Debugging** — 4-phase methodology for finding root cause before fixing
2. **Node.js Debugger** — `node inspect` REPL, CDP, heap/CPU profiling
3. **Python Debugger** — `pdb`, `debugpy` remote, `remote-pdb`, post-mortem

---

## A. Systematic Debugging (All Languages)

**Core principle:** NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.

### The Four Phases

#### Phase 1: Root Cause Investigation
- Read error messages carefully — don't skip past them
- Reproduce consistently — exact steps, every time
- Check recent changes — `git log --oneline -10`, `git diff`
- Gather evidence in multi-component systems — log at each component boundary
- Trace data flow — find where the bad value originates

**Completion:** Error reproduced, evidence gathered, root cause hypothesis formed.

#### Phase 2: Pattern Analysis
- Find working examples in the same codebase
- Compare against reference implementations
- Identify differences between working and broken
- Understand dependencies and assumptions

#### Phase 3: Hypothesis and Testing
- Form single hypothesis: "I think X is the root cause because Y"
- Test minimally — smallest possible change
- Verify before continuing
- If < 3 fixes failed: return to Phase 1
- If ≥ 3 fixes failed: question the architecture (see below)

#### Phase 4: Implementation
- Create failing test case first
- Implement single fix (root cause, not symptom)
- Verify fix — regression test + full suite
- If fix doesn't work: Rule of Three — after 3 failures, question architecture

### Red Flags — STOP and Follow Process
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)

---

## B. Node.js Debugger

### Tools
- **`node inspect`** — built-in, zero install, CLI REPL. Best for quick poking.
- **CDP via `chrome-remote-interface`** — scriptable, automate breakpoints.

### Quick Reference: `node inspect` REPL

```bash
node inspect path/to/script.js       # launch paused on first line
node inspect -p <pid>               # attach to running process
node --inspect-brk script.js        # pause on first line
```

| Command | Action |
|---------|--------|
| `n` / `next` | Step over |
| `s` / `step` | Step into |
| `o` / `out` | Step out |
| `c` / `cont` | Continue |
| `sb('file.js', 42)` | Set breakpoint |
| `bt` | Backtrace |
| `repl` | Drop into REPL in current scope |
| `exec expr` | Evaluate expression |
| `.exit` | Quit |

### Attaching to Running Process
```bash
kill -SIGUSR1 <pid>  # enable inspector
node inspect -p <pid>
# or
node inspect ws://127.0.0.1:9229/<uuid>
```

### Programmatic CDP
```bash
npm i -g chrome-remote-interface
node --inspect-brk=9229 target.js &
node /tmp/cdp-debug.js  # script that uses chrome-remote-interface
```

### Heap Snapshots & CPU Profiles
```javascript
// CPU profile
await client.Profiler.start();
await new Promise(r => setTimeout(r, 5000));
const { profile } = await client.Profiler.stop();
require('fs').writeFileSync('/tmp/cpu.cpuprofile', JSON.stringify(profile));

// Heap snapshot
const chunks = [];
client.HeapProfiler.addHeapSnapshotChunk(({ chunk }) => chunks.push(chunk));
await client.HeapProfiler.takeHeapSnapshot({ reportProgress: false });
require('fs').writeFileSync('/tmp/heap.heapsnapshot', chunks.join(''));
```

### Debugging Vitest/Jest Tests
```bash
node --inspect-brk ./node_modules/vitest/vitest.mjs run --no-file-parallelism src/app/foo.test.tsx
```

### Pitfalls
1. **Wrong line numbers in TS** — break at emitted JS line, or enable sourcemaps
2. **`--inspect` vs `--inspect-brk`** — use `--inspect-brk` to pause before code runs
3. **Port collisions** — use `--inspect=0` for random port
4. **`Ctrl+C` while paused** — target stays paused; `cont` first
5. **Security** — always bind to `127.0.0.1` (default)

---

## C. Python Debugger

### Tools
- **`breakpoint()` + pdb** — simplest, add to source, run normally
- **`python -m pdb`** — launch script under pdb, no source edits
- **`debugpy`** — remote/headless, DAP protocol, for long-running processes
- **`remote-pdb`** — terminal-friendly remote pdb via `nc`

### pdb Quick Reference

| Command | Action |
|---------|--------|
| `n` | Next line (step over) |
| `s` | Step into |
| `r` | Return from current function |
| `c` | Continue |
| `l` / `ll` | List source around current line |
| `w` | Where (stack trace) |
| `p expr` / `pp expr` | Print / pretty-print |
| `b file:line` | Set breakpoint |
| `interact` | Full Python REPL in current scope |
| `q` | Quit |

### Local breakpoint (simplest)
```python
def compute(x, y):
    result = some_helper(x)
    breakpoint()  # drops into pdb
    return result + y
```
Run normally. **Remove `breakpoint()` before committing.**

### Launch under pdb
```bash
python -m pdb path/to/script.py arg1
(Pdb) b path/to/script.py:42
(Pdb) c
```

### Debug pytest tests
```bash
python -m pytest tests/test_file.py::test_name --pdb -p no:xdist
```
**`-p no:xdist` is required** — pdb doesn't work under xdist.

### Post-mortem On Any Exception
```python
import pdb, sys
try:
    run_the_thing()
except Exception:
    pdb.post_mortem(sys.exc_info()[2])
```

### Remote Debug with debugpy
```python
import debugpy
debugpy.listen(("127.0.0.1", 5678))
debugpy.wait_for_client()  # blocks until attached
```

Launch with `-m debugpy`:
```bash
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client script.py
```

### remote-pdb (Simpler Alternative)
```python
pip install remote-pdb
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)  # blocks until connected
```
```bash
nc 127.0.0.1 4444  # get (Pdb) prompt
```

### Pitfalls
1. **pdb under pytest-xdist silently does nothing** — always use `-p no:xdist`
2. **`breakpoint()` in CI hangs the process** — never commit it
3. **`PYTHONBREAKPOINT=0`** disables all `breakpoint()` calls — check env
4. **pdb under pytest-xdist silently does nothing** — use `-p no:xdist` or `-n 0`
5. **Attach to PID fails on hardened kernels** — needs `ptrace_scope=0`
6. **`scripts/run_tests.sh` strips credentials** — bugs depending on real config won't reproduce
7. **Forking/multiprocessing** — pdb doesn't follow forks; debug each child separately
