#!/usr/bin/env bash
# Shared helpers for github-graphql skill scripts
# MIT License — Copyright 2026 Paul van Oorschot

set -euo pipefail

require_gh() {
  if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI not found. Install from https://cli.github.com/" >&2
    exit 1
  fi
  if ! gh auth status &>/dev/null 2>&1; then
    echo "Error: gh not authenticated. Run 'gh auth login'" >&2
    exit 1
  fi
}

# Execute a simple GraphQL query with no variables. Args: query_string
# For queries with variables, call `gh api graphql` directly with -f/-F flags.
graphql_query() {
  local query="$1"
  local result
  if ! result=$(gh api graphql -f query="$query" 2>&1); then
    if echo "$result" | grep -q "RATE_LIMITED"; then
      echo "Error: GitHub API rate limit exceeded. Check with rate_limit.sh" >&2
      exit 2
    fi
    echo "Error: GraphQL query failed: $result" >&2
    exit 1
  fi
  echo "$result"
}
