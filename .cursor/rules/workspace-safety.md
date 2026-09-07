# ANIS Khatamat Workspace Safety Rules

## Single Source of Truth

**CANONICAL DEVELOPMENT WORKTREE:**
- Path: `/Users/jaouad/Desktop/KHATAMAT/anis_merge_main`
- Branch: `main`

**This is the ONLY worktree allowed for normal product development.**

## Before Critical Operations

Before ANY of the following operations, you MUST verify workspace context:

1. **Commits** (git commit, git push)
2. **Release builds** (TestFlight, App Store)
3. **Database migrations**
4. **Firebase configuration changes**
5. **Firestore security rules changes**
6. **Large refactors** (affecting >5 files)
7. **Package upgrades** (pub upgrade, pod install)

## Required Verification

Run verification script OR manually check:

```bash
# Option 1: Run safety script
bash tools/verify_workspace.sh

# Option 2: Manual verification
pwd
git branch --show-current
git rev-parse HEAD
git status --short
```

**Expected state for normal development:**
- `pwd` → `/Users/jaouad/Desktop/KHATAMAT/anis_merge_main`
- `branch` → `main` (or approved feature branch)
- `status` → known uncommitted changes only

## Release Worktree Policy

**Release/TestFlight worktrees are temporary and read-only.**

**Naming convention:**
- Location: `/Users/jaouad/Desktop/KHATAMAT/releases/build_<N>_<shortsha>`
- Example: `releases/build_13_1780126`

**Creation:**
```bash
mkdir -p /Users/jaouad/Desktop/KHATAMAT/releases
git worktree add --detach releases/build_<N>_<shortsha> <exact-commit>
```

**Removal after TestFlight upload confirmed:**
```bash
git worktree remove releases/build_<N>_<shortsha>
```

**NEVER develop features inside release worktrees.**

## Historical/Preservation Worktrees

**These worktrees must NEVER be used for active development:**
- `anis_khatamat` (rescue/khatma-v2-phase1-20260906, preservation/wt-2026-08-22)
- `anis_khatamat_design` (design/ds-v1)
- `anis_khatamat_backup_*` (rescue branches)

**If you find yourself in one of these:**
1. STOP immediately
2. Switch to canonical worktree: `cd /Users/jaouad/Desktop/KHATAMAT/anis_merge_main`
3. Verify you're on `main` branch
4. Continue work from there

## Error Recovery

**If workspace verification fails:**
1. Stop current operation
2. Report which worktree you're in
3. Report which branch you're on
4. Ask user before proceeding
5. Do NOT assume it's safe to continue

## Context Preservation

Before ANY agent session involving code changes:
1. Print current `pwd`
2. Print current branch
3. Print HEAD commit
4. Print dirty file count
5. Confirm canonical workspace before proceeding

This prevents cross-worktree confusion and ensures all development happens in the single source of truth.
