#!/usr/bin/env bash
# Run arbitrary GitHub GraphQL queries
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

QUERY=""
FILE=""


show_help() {
  cat <<'EOF'
Usage: graphql.sh -q 'QUERY' | -f FILE [--var KEY=VALUE ...] [--json]

Run an arbitrary GitHub GraphQL query via `gh api graphql`.

Options:
  -q, --query QUERY     Inline GraphQL query string
  -f, --file FILE       Read query from a .graphql file
  --var KEY=VALUE       Pass a variable (string). Use --int-var for integers.
  --int-var KEY=VALUE   Pass an integer variable
  --json                Output raw JSON (default; kept for consistency)
  -h, --help            Show this help

Examples:
  graphql.sh -q '{ viewer { login } }'
  graphql.sh -q 'query($n: Int!) { viewer { repositories(first: $n) { nodes { name } } } }' --int-var n=5
  graphql.sh -f queries/repos.graphql --var org=github
  graphql.sh -q '{ rateLimit { remaining resetAt } }'

See: https://docs.github.com/en/graphql
EOF
  exit 0
}

GH_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--query) QUERY="$2"; shift 2 ;;
    -f|--file) FILE="$2"; shift 2 ;;
    --var) GH_ARGS+=(-f "$2"); shift 2 ;;
    --int-var) GH_ARGS+=(-F "$2"); shift 2 ;;
    --json) shift ;; # always JSON
    -h|--help) show_help ;;
    *) echo "Error: unknown option '$1'. See --help" >&2; exit 1 ;;
  esac
done

if [[ -n "$FILE" ]]; then
  if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE" >&2
    exit 1
  fi
  QUERY=$(<"$FILE")
fi

if [[ -z "$QUERY" ]]; then
  echo "Error: provide a query with -q or -f. See --help" >&2
  exit 1
fi

require_gh

result=$(gh api graphql -f query="$QUERY" "${GH_ARGS[@]}" 2>&1) || {
  echo "Error: $result" >&2; exit 1
}
echo "$result" | jq .
