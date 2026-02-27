#!/usr/bin/env bash
# Search GitHub issues and PRs via GraphQL
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

JSON_MODE=false
LIMIT=10
TYPE="both"
STATE="open"
REPO=""
LABEL=""
QUERY_STR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --state) STATE="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: search_issues.sh <query> [--type issue|pr|both] [--state open|closed|merged] [--repo owner/name] [--label LABEL] [--limit N] [--json]"
      exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) QUERY_STR="$1"; shift ;;
  esac
done

if [[ -z "$QUERY_STR" ]]; then
  echo "Error: search query required" >&2
  exit 1
fi

require_gh

# Build search qualifiers
search="$QUERY_STR"
[[ -n "$REPO" ]] && search="$search repo:$REPO"
[[ -n "$LABEL" ]] && search="$search label:\"$LABEL\""

case "$TYPE" in
  issue) search="$search type:issue" ;;
  pr) search="$search type:pr" ;;
  both) ;; # no filter
esac

case "$STATE" in
  open) search="$search state:open" ;;
  closed) search="$search state:closed" ;;
  merged) search="$search is:merged" ;;
esac

GQL='query($q: String!, $first: Int!) {
  search(query: $q, type: ISSUE, first: $first) {
    issueCount
    nodes {
      ... on Issue {
        __typename
        number
        title
        state
        url
        updatedAt
        repository { nameWithOwner }
        labels(first: 5) { nodes { name } }
        comments { totalCount }
      }
      ... on PullRequest {
        __typename
        number
        title
        state
        merged
        url
        updatedAt
        repository { nameWithOwner }
        labels(first: 5) { nodes { name } }
        comments { totalCount }
      }
    }
  }
}'

result=$(gh api graphql -f query="$GQL" -f q="$search" -F first="$LIMIT" 2>&1) || {
  echo "Error: $result" >&2; exit 1
}

nodes=$(echo "$result" | jq '.data.search.nodes')
count=$(echo "$nodes" | jq 'length')

if [[ "$count" == "0" ]]; then
  echo "No issues/PRs found." >&2
  exit 0
fi

if $JSON_MODE; then
  echo "$nodes" | jq .
  exit 0
fi

echo "$nodes" | jq -r '.[] | select(.number != null) |
  "#" + (.number | tostring) +
  " [" + (if .__typename == "PullRequest" then
    (if .merged then "merged" elif .state == "OPEN" then "open" else "closed" end)
  else
    (if .state == "OPEN" then "open" else "closed" end)
  end) + "] " +
  .title + " — " + .repository.nameWithOwner +
  "\n     Labels: " + (if (.labels.nodes | length) > 0 then [.labels.nodes[].name] | join(", ") else "none" end) +
  " | " + ((.comments.totalCount // 0) | tostring) + " comments" +
  " | " + (.updatedAt | split("T")[0])'
