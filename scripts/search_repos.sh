#!/usr/bin/env bash
# Search GitHub repositories via GraphQL
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

JSON_MODE=false
LIMIT=10
LANGUAGE=""
STARS=""
TOPIC=""
SORT=""
QUERY_STR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --stars) STARS="$2"; shift 2 ;;
    --topic) TOPIC="$2"; shift 2 ;;
    --sort) SORT="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: search_repos.sh <query> [--language LANG] [--stars \">N\"] [--topic TOPIC] [--limit N] [--sort stars|forks|updated] [--json]"
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

# Build GitHub search qualifier string
search="$QUERY_STR"
[[ -n "$LANGUAGE" ]] && search="$search language:$LANGUAGE"
[[ -n "$STARS" ]] && search="$search stars:$STARS"
[[ -n "$TOPIC" ]] && search="$search topic:$TOPIC"

# Validate sort value (GitHub search supports: stars, forks, updated)
case "${SORT:-stars}" in
  stars|forks|updated) ;;
  *) echo "Warning: unsupported sort '${SORT}', defaulting to stars" >&2; SORT="stars" ;;
esac

GQL_QUERY='query($q: String!, $first: Int!) {
  search(query: $q, type: REPOSITORY, first: $first) {
    repositoryCount
    nodes {
      ... on Repository {
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

# gh api graphql doesn't support passing variables via --raw-field variables well, use -f/-F
result=$(gh api graphql \
  -f query="$GQL_QUERY" \
  -f q="$search sort:${SORT:-stars}" \
  -F first="$LIMIT" 2>&1) || {
  echo "Error: $result" >&2; exit 1
}

count=$(echo "$result" | jq '.data.search.repositoryCount')
nodes=$(echo "$result" | jq '.data.search.nodes')

if [[ "$count" == "0" ]] || [[ "$(echo "$nodes" | jq 'length')" == "0" ]]; then
  echo "No repositories found." >&2
  exit 0
fi

if $JSON_MODE; then
  echo "$nodes" | jq '[.[] | {nameWithOwner, description, stargazerCount, url, updatedAt, primaryLanguage: .primaryLanguage.name, topics: [.repositoryTopics.nodes[].topic.name]}]'
  exit 0
fi

echo "$nodes" | jq -r '.[] |
  "⭐ " + (.stargazerCount | tostring | if (. | length) < 5 then (" " * (5 - (. | length))) + . else . end) +
  " | " + .nameWithOwner +
  (if .primaryLanguage.name then " [" + .primaryLanguage.name + "]" else "" end) +
  "\n         " + (.description // "No description") +
  (if (.repositoryTopics.nodes | length) > 0 then
    "\n         Topics: " + ([.repositoryTopics.nodes[].topic.name] | join(", "))
  else "" end)'
