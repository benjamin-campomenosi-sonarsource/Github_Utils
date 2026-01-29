# GitHub PR Spy 🔍

A bash script to quickly view all open Pull Requests where you are an **assignee**, **reviewer**, or have **already reviewed** across all your GitHub repositories. The script intelligently separates direct assignments from team-based review requests.

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


## Output Sections

The script organizes PRs into **three distinct sections**:

### 📋 READY PRs - Directly assigned to me
Non-draft PRs where you are either:
- Directly assigned as an assignee
- Directly requested as a reviewer (not via team)

### 📝 DRAFT PRs - Directly assigned to me
Draft PRs where you are directly assigned or requested as a reviewer.

### 👥 PRs - Assigned via Team/CODEOWNERS
PRs where you are:
- Requested as a reviewer via a team membership
- Assigned via CODEOWNERS rules
- Have already submitted a review (and not directly assigned)

## Output Format

Each PR entry displays:

| Column     | Description                         |
| ---------- | ----------------------------------- |
| Repository | The repository name (owner/repo)    |
| PR Number  | The pull request number             |
| Status     | Review status with color coding     |
| Title      | The PR title                        |
| Updated    | Last update date + checkout command |

### Status Colors

| Status     | Color    | Meaning                     |
| ---------- | -------- | --------------------------- |
| `APPROVED` | 🟢 Green  | PR has been approved        |
| `CHANGES`  | 🔴 Red    | Changes have been requested |
| `WAITING`  | 🟡 Yellow | Review is required          |
| `PENDING`  | ⚪ Gray   | No review decision yet      |

### Example Output

```
🔍 Fetching PRs (Assignee or Reviewer) across all projects...
--------------------------------------------------------------------------------

📋 READY PRs - Directly assigned to me
────────────────────────────────────────
  owner/my-repo         #123    APPROVED  Fix authentication bug
    └─ Updated: 2026-01-08 | gh pr checkout 123 -R owner/my-repo

📝 DRAFT PRs - Directly assigned to me
────────────────────────────────────────
  owner/my-repo         #789    PENDING   WIP: New dashboard
    └─ Updated: 2026-01-09 | gh pr checkout 789 -R owner/my-repo

👥 PRs - Assigned via Team/CODEOWNERS
────────────────────────────────────────
  owner/another-repo    #456    WAITING   Add new feature
    └─ Updated: 2026-01-07 | gh pr checkout 456 -R owner/another-repo
  [DRAFT] owner/team-repo #321  PENDING   Team feature draft
    └─ Updated: 2026-01-06 | gh pr checkout 321 -R owner/team-repo

--------------------------------------------------------------------------------
📦 Repositories checked (3): owner/my-repo owner/another-repo owner/team-repo
```

## How It Works

1. **Fetch PRs**: Uses `gh search prs` to find all open PRs where you are:
   - Assignee (`--assignee @me`)
   - Review requested (`--review-requested @me`)
   - Already reviewed (`--reviewed-by @me`)

2. **Categorize PRs**: For each review-requested PR, checks if you are directly requested or via team membership

3. **Separate Draft/Ready**: Splits directly assigned PRs into draft and non-draft categories

4. **Fetch Review Status**: For each PR, queries the review decision using `gh pr view`

5. **Display Results**: Shows PRs organized by section with color-coded status and checkout commands

6. **Summary**: Displays the total count of unique repositories checked

## Quick Checkout

Each PR line includes a ready-to-copy command to checkout the PR locally:

```bash
gh pr checkout <number> -R <owner/repo>
```
