#!/usr/bin/env bash
# Get detailed info about a GitHub repository
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

JSON_MODE=false
REPO=""

show_help() {
  cat <<'EOF'
Usage: repo_info.sh <owner/repo> [--json]

Get detailed information about a GitHub repository including stats,
topics, languages, recent releases, and contributor count.

Options:
  --json    Output raw JSON
  -h, --help  Show this help

Examples:
  repo_info.sh cli/cli
  repo_info.sh microsoft/vscode --json
  repo_info.sh anthropics/anthropic-sdk-python
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    -h|--help) show_help ;;
    -*) echo "Error: unknown option '$1'. See --help" >&2; exit 1 ;;
    *)
      if [[ -z "$REPO" ]]; then
        REPO="$1"
      else
        echo "Error: unexpected argument '$1'" >&2; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$REPO" ]] || [[ "$REPO" != */* ]]; then
  echo "Error: provide repo as owner/name (e.g. cli/cli). See --help" >&2
  exit 1
fi

OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

require_gh

GQL='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    nameWithOwner
    description
    url
    homepageUrl
    isArchived
    isFork
    isPrivate
    createdAt
    updatedAt
    pushedAt
    stargazerCount
    forkCount
    watchers { totalCount }
    issues(states: OPEN) { totalCount }
    pullRequests(states: OPEN) { totalCount }
    discussions { totalCount }
    primaryLanguage { name }
    languages(first: 10, orderBy: {field: SIZE, direction: DESC}) {
      nodes { name }
    }
    repositoryTopics(first: 10) { nodes { topic { name } } }
    releases(first: 5, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes { tagName name publishedAt }
    }
    defaultBranchRef { name }
    licenseInfo { spdxId name }
    mentionableUsers { totalCount }
  }
}'

result=$(gh api graphql -f query="$GQL" -f owner="$OWNER" -f name="$NAME" 2>&1) || {
  echo "Error: $result" >&2; exit 1
}

repo=$(echo "$result" | jq '.data.repository')

if [[ "$repo" == "null" ]]; then
  echo "Error: repository '$REPO' not found" >&2
  exit 1
fi

if $JSON_MODE; then
  echo "$repo" | jq '{
    nameWithOwner, description, url, homepageUrl,
    isArchived, isFork, isPrivate,
    createdAt, updatedAt, pushedAt,
    stars: .stargazerCount, forks: .forkCount,
    watchers: .watchers.totalCount,
    openIssues: .issues.totalCount,
    openPRs: .pullRequests.totalCount,
    discussions: .discussions.totalCount,
    primaryLanguage: .primaryLanguage.name,
    languages: [.languages.nodes[].name],
    topics: [.repositoryTopics.nodes[].topic.name],
    releases: [.releases.nodes[] | {tag: .tagName, name, date: .publishedAt}],
    defaultBranch: .defaultBranchRef.name,
    license: .licenseInfo.spdxId,
    contributors: .mentionableUsers.totalCount
  }'
  exit 0
fi

echo "$repo" | jq -r '
  .nameWithOwner + (if .isArchived then " [ARCHIVED]" else "" end) +
  (if .isPrivate then " [PRIVATE]" else "" end) +
  "\n" + (.description // "No description") +
  "\n" + .url +
  (if .homepageUrl and .homepageUrl != "" then "\nHomepage: " + .homepageUrl else "" end) +
  "\n" +
  "\n⭐ " + (.stargazerCount | tostring) + " stars | " +
  (.forkCount | tostring) + " forks | " +
  (.watchers.totalCount | tostring) + " watchers | " +
  (.mentionableUsers.totalCount | tostring) + " contributors" +
  "\n📋 " + (.issues.totalCount | tostring) + " open issues | " +
  (.pullRequests.totalCount | tostring) + " open PRs" +
  "\n🔤 " + (.primaryLanguage.name // "N/A") +
  " (" + ([.languages.nodes[].name] | join(", ")) + ")" +
  "\n📦 Branch: " + (.defaultBranchRef.name // "N/A") +
  " | License: " + (.licenseInfo.spdxId // "N/A") +
  (if (.repositoryTopics.nodes | length) > 0 then
    "\n🏷️  " + ([.repositoryTopics.nodes[].topic.name] | join(", "))
  else "" end) +
  (if (.releases.nodes | length) > 0 then
    "\n\nRecent releases:" +
    ([.releases.nodes[] | "\n  " + .tagName + " (" + (.publishedAt | split("T")[0]) + ")"] | join(""))
  else "" end)
'
