# GitHub Utils 🛠️

A collection of utility scripts and tools to enhance your GitHub workflow and productivity.

## Overview

This repository contains standalone utilities designed to simplify common GitHub operations, from tracking pull requests to automating repetitive tasks.

---

## 📁 Available Tools

### [`github_pullrequest_finder/`](./github_pullrequest_finder/)

**GitHub PR Spy** — A bash script that gives you a quick overview of all open Pull Requests where you are an assignee or reviewer across all your repositories.

**Features:**
- Scans all your GitHub repositories in one command
- Color-coded review status (Approved, Changes Requested, Waiting, Pending)
- Displays ready-to-use `gh pr checkout` commands for quick local checkout
- Formatted table output with repository, PR number, status, title, and last update date

**Quick Start:**
```bash
cd github_pullrequest_finder
chmod +x github_pullrequest_finder.sh
./github_pullrequest_finder.sh
```

> Requires [GitHub CLI (`gh`)](https://cli.github.com/) to be installed and authenticated.

---

## Requirements

- [GitHub CLI](https://cli.github.com/) — Most utilities in this repo leverage `gh` for GitHub API interactions
- Bash shell

