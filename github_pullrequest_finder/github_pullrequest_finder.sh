#!/bin/bash

# Define colors
BLUE='\033[1;34m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo  "\n${BLUE}🔍 Fetching PRs (Assignee or Reviewer) across all projects...${NC}"
echo  "${GRAY}--------------------------------------------------------------------------------${NC}"

# 1. Fetch PRs where user is ASSIGNEE
PR_ASSIGNEE=$(gh search prs --assignee "@me" --state open --json repository,number,title,url,updatedAt,isDraft --jq '.[] | "\(.repository.nameWithOwner) \(.number) \(.updatedAt) \(.isDraft) \(.title)"' 2>/dev/null)

# 2. Fetch PRs where user is a REVIEWER (review-requested or already reviewed)
PR_REVIEWER=$(gh search prs --review-requested "@me" --state open --json repository,number,title,url,updatedAt,isDraft --jq '.[] | "\(.repository.nameWithOwner) \(.number) \(.updatedAt) \(.isDraft) \(.title)"' 2>/dev/null)

PR_REVIEWED=$(gh search prs --reviewed-by "@me" --state open --json repository,number,title,url,updatedAt,isDraft --jq '.[] | "\(.repository.nameWithOwner) \(.number) \(.updatedAt) \(.isDraft) \(.title)"' 2>/dev/null)

# 3. Combine and deduplicate (using repo+number as unique key)
PR_DATA=$(printf "%s\n%s\n%s" "$PR_ASSIGNEE" "$PR_REVIEWER" "$PR_REVIEWED" | sort -u -k1,2)

# Track unique repositories
REPOS_LIST=""

# 2. Loop through them to get the review status using 'pr view'
while read -r REPO NUMBER UPDATED ISDRAFT TITLE; do
    [ -z "$REPO" ] && continue
    
    # Add repo to the list (we'll dedupe later)
    REPOS_LIST="$REPOS_LIST$REPO"$'\n'
    
    # Get the review decision for this specific PR
    DECISION=$(gh pr view "$NUMBER" -R "$REPO" --json reviewDecision --jq '.reviewDecision' 2>/dev/null)
    
    # Format the draft indicator
    if [ "$ISDRAFT" = "true" ]; then
        DRAFT_TAG="${GRAY}[DRAFT]${NC} "
    else
        DRAFT_TAG=""
    fi

    # Format the decision label
    case $DECISION in
        "APPROVED")          STATUS_TAG="${GREEN}APPROVED${NC} " ;;
        "CHANGES_REQUESTED") STATUS_TAG="${RED}CHANGES ${NC} " ;;
        "REVIEW_REQUIRED")   STATUS_TAG="${YELLOW}WAITING ${NC} " ;;
        *)                   STATUS_TAG="${GRAY}PENDING ${NC} " ;;
    esac

    # Format the date (removes the time/seconds)
    SHORT_DATE=$(echo $UPDATED | cut -d'T' -f1)

    # Print the formatted row
    printf "%s \t %s %b%b%s\n" "$REPO" "#$NUMBER" "$DRAFT_TAG" "$STATUS_TAG" "$TITLE"
    echo "  ${GRAY}└─ Updated: $SHORT_DATE | gh pr checkout $NUMBER -R $REPO${NC}"
done <<< "$PR_DATA"

echo "${GRAY}--------------------------------------------------------------------------------${NC}"

# Display unique repositories checked
UNIQUE_REPOS=$(echo "$REPOS_LIST" | sort -u | grep -v '^$')
REPO_COUNT=$(echo "$UNIQUE_REPOS" | grep -c .)

if [ "$REPO_COUNT" -gt 0 ]; then
    echo "${BLUE}📦 Repositories checked ($REPO_COUNT):${NC} ${GRAY}$(echo "$UNIQUE_REPOS" | tr '\n' ' ')${NC}"
else
    echo "${GRAY}No PRs found.${NC}"
fi
echo ""