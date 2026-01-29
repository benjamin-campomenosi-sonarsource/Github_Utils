#!/bin/bash

# Define colors
BLUE='\033[1;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Get current GitHub username
CURRENT_USER=$(gh api user --jq '.login' 2>/dev/null)

echo  "\n${BLUE}🔍 Fetching PRs (Assignee or Reviewer) across all projects...${NC}"
echo  "${GRAY}--------------------------------------------------------------------------------${NC}"

# Function to display a PR row
display_pr() {
    local REPO=$1
    local NUMBER=$2
    local UPDATED=$3
    local TITLE=$4
    
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
    printf "  %s \t #%s %b%s\n" "$REPO" "$NUMBER" "$STATUS_TAG" "$TITLE"
    echo "    ${GRAY}└─ Updated: $SHORT_DATE | gh pr checkout $NUMBER -R $REPO${NC}"
}

# 1. Fetch PRs where user is ASSIGNEE (always direct)
PR_ASSIGNEE=$(gh search prs --assignee "@me" --state open --json repository,number,title,updatedAt,isDraft --jq '.[] | "\(.repository.nameWithOwner)|\(.number)|\(.updatedAt)|\(.isDraft)|\(.title)"' 2>/dev/null)

# 2. Fetch PRs where user is REVIEW-REQUESTED (need to check if direct or via team)
PR_REVIEW_REQUESTED=$(gh search prs --review-requested "@me" --state open --json repository,number,title,updatedAt,isDraft --jq '.[] | "\(.repository.nameWithOwner)|\(.number)|\(.updatedAt)|\(.isDraft)|\(.title)"' 2>/dev/null)

# 3. Fetch PRs where user has already REVIEWED
PR_REVIEWED=$(gh search prs --reviewed-by "@me" --state open --json repository,number,title,updatedAt,isDraft --jq '.[] | "\(.repository.nameWithOwner)|\(.number)|\(.updatedAt)|\(.isDraft)|\(.title)"' 2>/dev/null)

# Separate review-requested PRs into direct vs team
PR_DIRECT_REVIEW=""
PR_TEAM_REVIEW=""

while IFS='|' read -r REPO NUMBER UPDATED ISDRAFT TITLE; do
    [ -z "$REPO" ] && continue
    
    # Check if user is directly in requestedReviewers (not via team)
    IS_DIRECT=$(gh pr view "$NUMBER" -R "$REPO" --json reviewRequests --jq ".reviewRequests[]? | select(.login == \"$CURRENT_USER\") | .login" 2>/dev/null)
    
    if [ -n "$IS_DIRECT" ]; then
        PR_DIRECT_REVIEW="${PR_DIRECT_REVIEW}${REPO}|${NUMBER}|${UPDATED}|${ISDRAFT}|${TITLE}"$'\n'
    else
        PR_TEAM_REVIEW="${PR_TEAM_REVIEW}${REPO}|${NUMBER}|${UPDATED}|${ISDRAFT}|${TITLE}"$'\n'
    fi
done <<< "$PR_REVIEW_REQUESTED"

# Combine direct PRs (assignee + direct review requests)
PR_DIRECT=$(printf "%s\n%s" "$PR_ASSIGNEE" "$PR_DIRECT_REVIEW" | sort -u)

# Add reviewed PRs that aren't already in direct or team lists to team list
while IFS='|' read -r REPO NUMBER UPDATED ISDRAFT TITLE; do
    [ -z "$REPO" ] && continue
    # Check if this PR is NOT already in direct or team lists
    if ! echo "$PR_DIRECT" | grep -q "^${REPO}|${NUMBER}|" && ! echo "$PR_TEAM_REVIEW" | grep -q "^${REPO}|${NUMBER}|"; then
        PR_TEAM_REVIEW="${PR_TEAM_REVIEW}${REPO}|${NUMBER}|${UPDATED}|${ISDRAFT}|${TITLE}"$'\n'
    fi
done <<< "$PR_REVIEWED"

# Deduplicate team PRs
PR_TEAM_REVIEW=$(echo "$PR_TEAM_REVIEW" | sort -u)

# Track unique repositories
REPOS_LIST=""

# ============================================================================
# SECTION 1: Ready PRs (non-draft) directly assigned
# ============================================================================
echo "\n${CYAN}📋 READY PRs - Directly assigned to me${NC}"
echo "${GRAY}────────────────────────────────────────${NC}"
FOUND_READY=false
while IFS='|' read -r REPO NUMBER UPDATED ISDRAFT TITLE; do
    [ -z "$REPO" ] && continue
    if [ "$ISDRAFT" != "true" ]; then
        FOUND_READY=true
        REPOS_LIST="$REPOS_LIST$REPO"$'\n'
        display_pr "$REPO" "$NUMBER" "$UPDATED" "$TITLE"
    fi
done <<< "$PR_DIRECT"
if [ "$FOUND_READY" = false ]; then
    echo "  ${GRAY}No ready PRs found.${NC}"
fi

# ============================================================================
# SECTION 2: Draft PRs directly assigned
# ============================================================================
echo "\n${MAGENTA}📝 DRAFT PRs - Directly assigned to me${NC}"
echo "${GRAY}────────────────────────────────────────${NC}"
FOUND_DRAFT=false
while IFS='|' read -r REPO NUMBER UPDATED ISDRAFT TITLE; do
    [ -z "$REPO" ] && continue
    if [ "$ISDRAFT" = "true" ]; then
        FOUND_DRAFT=true
        REPOS_LIST="$REPOS_LIST$REPO"$'\n'
        display_pr "$REPO" "$NUMBER" "$UPDATED" "$TITLE"
    fi
done <<< "$PR_DIRECT"
if [ "$FOUND_DRAFT" = false ]; then
    echo "  ${GRAY}No draft PRs found.${NC}"
fi

# ============================================================================
# SECTION 3: PRs via team/application owner (CODEOWNERS)
# ============================================================================
echo "\n${YELLOW}👥 PRs - Assigned via Team/CODEOWNERS${NC}"
echo "${GRAY}────────────────────────────────────────${NC}"
FOUND_TEAM=false
while IFS='|' read -r REPO NUMBER UPDATED ISDRAFT TITLE; do
    [ -z "$REPO" ] && continue
    FOUND_TEAM=true
    REPOS_LIST="$REPOS_LIST$REPO"$'\n'
    
    # Get review decision
    DECISION=$(gh pr view "$NUMBER" -R "$REPO" --json reviewDecision --jq '.reviewDecision' 2>/dev/null)
    case $DECISION in
        "APPROVED")          STATUS_TAG="${GREEN}APPROVED${NC} " ;;
        "CHANGES_REQUESTED") STATUS_TAG="${RED}CHANGES ${NC} " ;;
        "REVIEW_REQUIRED")   STATUS_TAG="${YELLOW}WAITING ${NC} " ;;
        *)                   STATUS_TAG="${GRAY}PENDING ${NC} " ;;
    esac
    SHORT_DATE=$(echo $UPDATED | cut -d'T' -f1)
    
    if [ "$ISDRAFT" = "true" ]; then
        printf "  ${GRAY}[DRAFT]${NC} %s \t #%s %b%s\n" "$REPO" "$NUMBER" "$STATUS_TAG" "$TITLE"
    else
        printf "  %s \t #%s %b%s\n" "$REPO" "$NUMBER" "$STATUS_TAG" "$TITLE"
    fi
    echo "    ${GRAY}└─ Updated: $SHORT_DATE | gh pr checkout $NUMBER -R $REPO${NC}"
done <<< "$PR_TEAM_REVIEW"
if [ "$FOUND_TEAM" = false ]; then
    echo "  ${GRAY}No PRs via team/CODEOWNERS found.${NC}"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo "\n${GRAY}--------------------------------------------------------------------------------${NC}"

# Display unique repositories checked
UNIQUE_REPOS=$(echo "$REPOS_LIST" | sort -u | grep -v '^$')
REPO_COUNT=$(echo "$UNIQUE_REPOS" | grep -c . 2>/dev/null || echo "0")

if [ "$REPO_COUNT" -gt 0 ]; then
    echo "${BLUE}📦 Repositories checked ($REPO_COUNT):${NC} ${GRAY}$(echo "$UNIQUE_REPOS" | tr '\n' ' ')${NC}"
else
    echo "${GRAY}No PRs found.${NC}"
fi
echo ""
