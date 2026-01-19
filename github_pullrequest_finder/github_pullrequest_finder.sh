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

# 1. Fetch the PRs using search
# 2. Loop through them to get the review status using 'pr view'
gh search prs --assignee "@me"  --reviewed-by "@me" --state open --json repository,number,title,url,updatedAt --jq '.[] | "\(.repository.nameWithOwner) \(.number) \(.updatedAt) \(.title)"' | while read -r REPO NUMBER UPDATED TITLE; do
    
    # Get the review decision for this specific PR
    DECISION=$(gh pr view "$NUMBER" -R "$REPO" --json reviewDecision --jq '.reviewDecision' 2>/dev/null)
    
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
    printf "%s \t %s %b %s\n" "$REPO" "#$NUMBER" "$STATUS_TAG" "$TITLE"
    echo "  ${GRAY}└─ Updated: $SHORT_DATE | gh pr checkout $NUMBER -R $REPO${NC}"
done

echo "${GRAY}--------------------------------------------------------------------------------${NC}\n"