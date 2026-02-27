#!/usr/bin/env bash
# List repositories for a GitHub organization
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

JSON_MODE=false
LIMIT=20
LANGUAGE=""
SORT="stars"
ORG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --sort) SORT="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: org_repos.sh <org> [--sort stars|updated|pushed|name] [--limit N] [--language LANG] [--json]"
      exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) ORG="$1"; shift ;;
  esac
done

if [[ -z "$ORG" ]]; then
  echo "Error: organization name required" >&2
  exit 1
fi

require_gh

# Map sort to GraphQL field/direction
ORDER_FIELD="STARGAZERS"
case "$SORT" in
  stars) ORDER_FIELD="STARGAZERS" ;;
  updated) ORDER_FIELD="UPDATED_AT" ;;
  pushed) ORDER_FIELD="PUSHED_AT" ;;
  name) ORDER_FIELD="NAME" ;;
esac

GQL='query($org: String!, $first: Int!, $orderField: RepositoryOrderField!) {
  organization(login: $org) {
    repositories(first: $first, orderBy: {field: $orderField, direction: DESC}) {
      totalCount
      nodes {
        nameWithOwner
        description
        stargazerCount
        url
        updatedAt
        primaryLanguage { name }
        repositoryTopics(first: 5) { nodes { topic { name } } }
      }
    }
  }
}'

# Fetch more if filtering by language (since filter is client-side)
fetch_limit=$LIMIT
[[ -n "$LANGUAGE" ]] && fetch_limit=$((LIMIT * 5 > 100 ? 100 : LIMIT * 5))

result=$(gh api graphql \
  -f query="$GQL" \
  -f org="$ORG" \
  -F first="$fetch_limit" \
  -f orderField="$ORDER_FIELD" 2>&1) || {
  echo "Error: $result" >&2; exit 1
}

total=$(echo "$result" | jq '.data.organization.repositories.totalCount')
nodes=$(echo "$result" | jq '.data.organization.repositories.nodes')

# Filter by language if specified
if [[ -n "$LANGUAGE" ]]; then
  nodes=$(echo "$nodes" | jq --arg lang "$LANGUAGE" --argjson lim "$LIMIT" '[.[] | select(.primaryLanguage.name != null and (.primaryLanguage.name | ascii_downcase) == ($lang | ascii_downcase))][:$lim]')
fi

count=$(echo "$nodes" | jq 'length')

if $JSON_MODE; then
  echo "$nodes" | jq '[.[] | {nameWithOwner, description, stargazerCount, url, updatedAt, primaryLanguage: .primaryLanguage.name, topics: [.repositoryTopics.nodes[].topic.name]}]'
  exit 0
fi

echo "Repositories for $ORG (showing $count of $total):"
echo
echo "$nodes" | jq -r '.[] |
  "⭐ " + (.stargazerCount | tostring | if (. | length) < 5 then (" " * (5 - (. | length))) + . else . end) +
  " | " + .nameWithOwner +
  (if .primaryLanguage.name then " [" + .primaryLanguage.name + "]" else "" end) +
  "\n         " + (.description // "No description")'
