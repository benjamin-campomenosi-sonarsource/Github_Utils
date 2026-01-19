# GitHub PR Spy 🔍

A simple bash script to quickly view all open Pull Requests where you are either an **assignee** or a **reviewer** across all your GitHub repositories.

## Prerequisites

[GitHub CLI (`gh`)](https://cli.github.com/) must be installed and authenticated

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

## Add as a Shortcut (Optional)

You can make `github_pullrequest_finder.sh` available everywhere from your terminal by adding it to your `PATH` or creating an alias in your shell configuration.

### Option 1: Add to PATH

Move or symlink the script into a directory that's already in your `PATH` (e.g., `/usr/local/bin`):

```bash
# From inside the repo:
chmod +x github_pullrequest_finder.sh
sudo ln -s "$(pwd)/github_pullrequest_finder.sh" /usr/local/bin/github_pullrequest_finder
```

Now you can just run:
```bash
github_pullrequest_finder
```
from anywhere.

### Option 2: Add an Alias

Add this line to your `~/.zshrc`, `~/.bashrc`, or `~/.bash_profile`:

```bash
alias git_pr_finder="sh /path/to/github_pullrequest_finder/github_pullrequest_finder.sh"
```

Replace `/path/to/github_pullrequest_finder/` with the actual path where you cloned this repository.

After saving, run `source ~/.zshrc` (or your respective shell config) to apply changes. Now you can use:

```bash
git_pr_finder
```
from any terminal window to instantly see your open PRs.


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

