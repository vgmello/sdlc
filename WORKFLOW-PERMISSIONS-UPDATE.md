# Workflow Permissions Update Required

## Summary
This document outlines the changes needed to enable Claude to modify GitHub Actions workflows.

## Required Change

Add `workflows: write` permission to `.github/workflows/claude.yml`:

### Location
File: `.github/workflows/claude.yml`
Line: 25 (after `issues: write`)

### Current Configuration (lines 21-25)
```yaml
    permissions:
      contents: write
      pull-requests: write
      issues: write

    steps:
```

### Updated Configuration (lines 21-26)
```yaml
    permissions:
      contents: write
      pull-requests: write
      issues: write
      workflows: write

    steps:
```

## Why This Is Needed

GitHub's security model prevents GitHub Apps (including `github-actions[bot]`) from creating or modifying workflow files without explicit `workflows: write` permission. This is a security measure to prevent unauthorized workflow modifications.

Once this permission is added, Claude will be able to:
- ✅ Create new workflow files
- ✅ Modify existing workflow files
- ✅ Create pull requests with workflow changes
- ✅ Move `cleanup-claude-state-workflow.yml` to `.github/workflows/`

## After Adding This Permission

1. Move `cleanup-claude-state-workflow.yml` to `.github/workflows/cleanup-claude-state.yml`
2. The cleanup workflow will automatically activate
3. Future workflow modifications by Claude will work seamlessly

## Branch Naming Convention

As part of this update, the branch naming convention is now:
- Format: `issue-{#id}-description`
- Example: `issue-4-add-cleanup-script`
- Claude state branches: `issue-{#id}-claude`

This convention is used by the cleanup workflow to identify and delete corresponding Claude state branches when issue branches are deleted.
