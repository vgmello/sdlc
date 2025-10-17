# User Permission Validation for Claude Workflow

This PR implements user permission validation for the Claude workflow to ensure only authorized users can trigger the workflow.

## Files Included

### `claude-with-permissions.yml.txt`
This file contains the updated workflow with:
- User permission validation
- `workflows: write` permission added
- Support for all event types (issues, comments, PRs, reviews)

## What Changed

### 1. Added `workflows: write` Permission
```yaml
permissions:
  contents: write
  pull-requests: write
  issues: write
  workflows: write  # NEW - allows Claude to modify workflow files in the future
```

### 2. User Actor Extraction
The workflow now extracts the username from all event types:
- Issues: `github.event.issue.user.login`
- Issue comments: `github.event.comment.user.login`
- PR review comments: `github.event.comment.user.login`
- PR reviews: `github.event.review.user.login`

### 3. Permission Check Step
A new step validates user permissions before running Claude:
- Queries GitHub API: `/repos/{owner}/{repo}/collaborators/{user}/permission`
- Checks if user has `write`, `maintain`, or `admin` permission
- Sets output variable `has_permission` (true/false)

### 4. Conditional Execution
The "Run Claude Code" step now only executes when:
```yaml
if: steps.permission_check.outputs.has_permission == 'true'
```

### 5. User Feedback
When permissions are insufficient, the workflow:
- Posts a comment on the issue/PR explaining the permission requirement
- Shows the user's current permission level
- Directs them to contact a repository administrator

## How to Apply

### Option 1: Manual Copy (Recommended)
```bash
# Backup current workflow
cp .github/workflows/claude.yml .github/workflows/claude.yml.backup

# Apply new workflow
cp claude-with-permissions.yml.txt .github/workflows/claude.yml

# Commit and push
git add .github/workflows/claude.yml
git commit -m "Apply user permission validation to Claude workflow"
git push
```

### Option 2: Rename
```bash
mv .github/workflows/claude.yml .github/workflows/claude.yml.backup
mv claude-with-permissions.yml.txt .github/workflows/claude.yml
git add .github/workflows/
git commit -m "Apply user permission validation to Claude workflow"
git push
```

## Testing

After applying, test with:
1. A user with write access mentions `@claude` - should work normally
2. A user without write access mentions `@claude` - should receive permission denied message

## Security Benefits

- ✅ Prevents unauthorized users from triggering expensive AI operations
- ✅ Maintains audit trail of permission checks
- ✅ Provides clear feedback instead of silent failures
- ✅ Works with both GitHub PAT and job tokens

## Future Workflow Changes

With `workflows: write` permission added, Claude can now modify workflow files directly in future sessions, eliminating the need for workarounds.

Closes #17
