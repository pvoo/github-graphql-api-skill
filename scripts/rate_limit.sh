#!/usr/bin/env bash
# Show GitHub GraphQL API rate limit status
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

JSON_MODE=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON_MODE=true ;;
    --help|-h)
      echo "Usage: rate_limit.sh [--json]"
      echo "Show current GitHub GraphQL API rate limit status."
      exit 0 ;;
  esac
done

require_gh

QUERY='{ rateLimit { limit cost remaining resetAt } }'
result=$(graphql_query "$QUERY")

if $JSON_MODE; then
  echo "$result" | jq '.data.rateLimit'
  exit 0
fi

limit=$(echo "$result" | jq -r '.data.rateLimit.limit')
remaining=$(echo "$result" | jq -r '.data.rateLimit.remaining')
used=$((limit - remaining))
reset_at=$(echo "$result" | jq -r '.data.rateLimit.resetAt')
reset_fmt=$(date -d "$reset_at" '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || echo "$reset_at")

echo "GitHub GraphQL Rate Limit:"
echo "  Used:      $used / $limit"
echo "  Remaining: $remaining"
echo "  Resets at:  $reset_fmt"
