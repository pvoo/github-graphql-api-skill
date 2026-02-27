#!/usr/bin/env bash
# Get GitHub user or organization profile info
# MIT License — Copyright 2026 Paul van Oorschot
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

JSON_MODE=false
USERNAME=""

show_help() {
  cat <<'EOF'
Usage: user_info.sh <username> [--json]

Get profile info for a GitHub user or organization, including
repos, followers, contributions, and organization memberships.

Options:
  --json    Output raw JSON
  -h, --help  Show this help

Examples:
  user_info.sh torvalds
  user_info.sh microsoft --json
  user_info.sh octocat
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    -h|--help) show_help ;;
    -*) echo "Error: unknown option '$1'. See --help" >&2; exit 1 ;;
    *)
      if [[ -z "$USERNAME" ]]; then USERNAME="$1"; else echo "Error: unexpected argument '$1'" >&2; exit 1; fi
      shift ;;
  esac
done

if [[ -z "$USERNAME" ]]; then
  echo "Error: username required. See --help" >&2
  exit 1
fi

require_gh

# Try user first, fall back to organization
USER_GQL='query($login: String!) {
  user(login: $login) {
    __typename
    login
    name
    bio
    company
    location
    websiteUrl
    twitterUsername
    avatarUrl
    createdAt
    followers { totalCount }
    following { totalCount }
    repositories(privacy: PUBLIC) { totalCount }
    starredRepositories { totalCount }
    contributionsCollection { contributionCalendar { totalContributions } }
    organizations(first: 10) { nodes { login name } }
    pinnedItems(first: 6, types: REPOSITORY) {
      nodes { ... on Repository { nameWithOwner stargazerCount description } }
    }
  }
}'

ORG_GQL='query($login: String!) {
  organization(login: $login) {
    __typename
    login
    name
    description
    websiteUrl
    location
    email
    twitterUsername
    avatarUrl
    createdAt
    repositories(privacy: PUBLIC) { totalCount }
    membersWithRole { totalCount }
    teams { totalCount }
    pinnedItems(first: 6, types: REPOSITORY) {
      nodes { ... on Repository { nameWithOwner stargazerCount description } }
    }
  }
}'

# Try user (may fail for orgs, that's ok)
# gh appends error text after JSON, so extract just the JSON object
raw=$(gh api graphql -f query="$USER_GQL" -f login="$USERNAME" 2>/dev/null) || true
user_data=$(echo "$raw" | jq '.data.user // null' 2>/dev/null || echo "null")

if [[ "$user_data" != "null" ]]; then
  if $JSON_MODE; then
    echo "$user_data" | jq '{
      type: .__typename, login, name, bio, company, location,
      websiteUrl, twitterUsername, createdAt,
      followers: .followers.totalCount,
      following: .following.totalCount,
      publicRepos: .repositories.totalCount,
      starredRepos: .starredRepositories.totalCount,
      contributions: .contributionsCollection.contributionCalendar.totalContributions,
      organizations: [.organizations.nodes[] | {login, name}],
      pinnedRepos: [.pinnedItems.nodes[] | {nameWithOwner, stargazerCount, description}]
    }'
    exit 0
  fi

  echo "$user_data" | jq -r '
    .login + (if .name then " (" + .name + ")" else "" end) +
    (if .bio then "\n" + .bio else "" end) +
    (if .company then "\n🏢 " + .company else "" end) +
    (if .location then " | 📍 " + .location else "" end) +
    (if .websiteUrl then "\n🔗 " + .websiteUrl else "" end) +
    "\n" +
    "\n👥 " + (.followers.totalCount | tostring) + " followers | " +
    (.following.totalCount | tostring) + " following" +
    "\n📦 " + (.repositories.totalCount | tostring) + " public repos | " +
    "⭐ " + (.starredRepositories.totalCount | tostring) + " starred" +
    "\n📊 " + (.contributionsCollection.contributionCalendar.totalContributions | tostring) + " contributions (last year)" +
    (if (.organizations.nodes | length) > 0 then
      "\n🏛️  Orgs: " + ([.organizations.nodes[].login] | join(", "))
    else "" end) +
    (if (.pinnedItems.nodes | length) > 0 then
      "\n\nPinned repos:" +
      ([.pinnedItems.nodes[] | "\n  ⭐ " + (.stargazerCount | tostring) + " " + .nameWithOwner + " — " + (.description // "No description")] | join(""))
    else "" end)
  '
  exit 0
fi

# Try organization
raw=$(gh api graphql -f query="$ORG_GQL" -f login="$USERNAME" 2>/dev/null) || true
org_data=$(echo "$raw" | jq '.data.organization // null' 2>/dev/null || echo "null")

if [[ "$org_data" != "null" ]]; then
  if $JSON_MODE; then
    echo "$org_data" | jq '{
      type: .__typename, login, name, description, location,
      websiteUrl, email, twitterUsername, createdAt,
      publicRepos: .repositories.totalCount,
      members: .membersWithRole.totalCount,
      teams: .teams.totalCount,
      pinnedRepos: [.pinnedItems.nodes[] | {nameWithOwner, stargazerCount, description}]
    }'
    exit 0
  fi

  echo "$org_data" | jq -r '
    .login + " [Organization]" + (if .name then " — " + .name else "" end) +
    (if .description then "\n" + .description else "" end) +
    (if .location then "\n📍 " + .location else "" end) +
    (if .websiteUrl then " | 🔗 " + .websiteUrl else "" end) +
    (if .email then " | ✉️  " + .email else "" end) +
    "\n" +
    "\n📦 " + (.repositories.totalCount | tostring) + " public repos | " +
    "👥 " + (.membersWithRole.totalCount | tostring) + " members | " +
    "🏷️  " + (.teams.totalCount | tostring) + " teams" +
    (if (.pinnedItems.nodes | length) > 0 then
      "\n\nPinned repos:" +
      ([.pinnedItems.nodes[] | "\n  ⭐ " + (.stargazerCount | tostring) + " " + .nameWithOwner + " — " + (.description // "No description")] | join(""))
    else "" end)
  '
  exit 0
fi

echo "Error: user or organization '$USERNAME' not found" >&2
exit 1
