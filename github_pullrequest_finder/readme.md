# GitHub PR Spy 🔍

A simple bash script to quickly view all open Pull Requests where you are either an **assignee** or a **reviewer** across all your GitHub repositories.

## Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) must be installed and authenticated
  
  ```bash
  # Install on macOS
  brew install gh
  
  # Authenticate
  gh auth login
  ```

## Usage

```bash
# Make the script executable (first time only)
chmod +x github_pullrequest_finder.sh

# Run the script
./github_pullrequest_finder.sh
```

## Output

The script displays a formatted table with:

| Column | Description |
|--------|-------------|
| Repository | The repository name (owner/repo) |
| PR Number | The pull request number |
| Status | Review status with color coding |
| Title | The PR title |
| Updated | Last update date + checkout command |

### Status Colors

| Status | Color | Meaning |
|--------|-------|---------|
| `APPROVED` | 🟢 Green | PR has been approved |
| `CHANGES` | 🔴 Red | Changes have been requested |
| `WAITING` | 🟡 Yellow | Review is required |
| `PENDING` | ⚪ Gray | No review decision yet |

### Example Output

```
🔍 Fetching PRs (Assignee or Reviewer) across all projects...
--------------------------------------------------------------------------------
owner/my-repo             #123    APPROVED  Fix authentication bug
  └─ Updated: 2026-01-08 | gh pr checkout 123 -R owner/my-repo
owner/another-repo        #456    WAITING   Add new feature
  └─ Updated: 2026-01-07 | gh pr checkout 456 -R owner/another-repo
--------------------------------------------------------------------------------
```

## How It Works

1. **Search PRs**: Uses `gh search prs` to find all open PRs where you are assignee or reviewer
2. **Fetch Review Status**: For each PR, queries the review decision using `gh pr view`
3. **Format Output**: Displays results with color-coded status and a ready-to-use checkout command

## Quick Checkout

Each PR line includes a ready-to-copy command to checkout the PR locally:

```bash
gh pr checkout <number> -R <owner/repo>
```

