---
name: github-graphql
version: "1.0.0"
author: pvoo
description: Query GitHub's GraphQL API v4 — search repos, inspect repositories, look up users/orgs, search issues/PRs, run arbitrary queries, and check rate limits. Use when you need richer GitHub data than REST provides.
---

# GitHub GraphQL API Skill

A collection of shell scripts for querying GitHub's GraphQL API v4 via the `gh` CLI. Search repos, inspect repositories, look up users/orgs, search issues/PRs, run arbitrary GraphQL queries, and monitor rate limits.

## Prerequisites

- **`gh` CLI** — [Install](https://cli.github.com/) and authenticate: `gh auth login`
- **`jq`** — JSON processor (usually pre-installed)

## Scripts

### `scripts/graphql.sh` — Run arbitrary GraphQL queries
```bash
graphql.sh -q '{ viewer { login } }'
graphql.sh -q 'query($n: Int!) { viewer { repositories(first: $n) { nodes { name } } } }' --int-var n=5
graphql.sh -f queries/my_query.graphql --var org=github
```

### `scripts/search_repos.sh` — Search repositories
```bash
search_repos.sh <query> [--language LANG] [--stars ">N"] [--topic TOPIC] [--limit N] [--sort stars|forks|updated] [--json]
```
```bash
search_repos.sh "graphql client" --language typescript --stars ">100"
search_repos.sh "machine learning" --topic pytorch --limit 5 --json
```

### `scripts/repo_info.sh` — Detailed repository info
```bash
repo_info.sh <owner/repo> [--json]
```
```bash
repo_info.sh cli/cli
repo_info.sh microsoft/vscode --json
```
Shows: stars, forks, watchers, contributors, languages, topics, recent releases, license, open issues/PRs.

### `scripts/user_info.sh` — User or organization profile
```bash
user_info.sh <username> [--json]
```
```bash
user_info.sh torvalds
user_info.sh microsoft --json
```
Shows: bio, followers, repos, contributions, orgs (users) or members/teams (orgs), pinned repos.

### `scripts/org_repos.sh` — List organization repositories
```bash
org_repos.sh <org> [--sort stars|updated|pushed|name] [--limit N] [--language LANG] [--json]
```
```bash
org_repos.sh github --limit 10
org_repos.sh microsoft --language python --sort stars --json
```

### `scripts/search_issues.sh` — Search issues and pull requests
```bash
search_issues.sh <query> [--type issue|pr|both] [--state open|closed|merged] [--repo owner/name] [--label LABEL] [--limit N] [--json]
```
```bash
search_issues.sh "pagination bug" --repo graphql/graphql-js --type issue
search_issues.sh "breaking change" --type pr --state merged --limit 5
```

### `scripts/rate_limit.sh` — Check API rate limit
```bash
rate_limit.sh [--json]
```

## Output Modes

All scripts support:
- **Default** — Human-friendly formatted output
- **`--json`** — Structured JSON for programmatic use
- **`--help`** — Usage info with examples

## Environment

| Variable | Purpose |
|----------|---------|
| `GH_TOKEN` | Alternative to `gh auth login` (optional) |
| `GH_HOST` | GitHub Enterprise host (optional) |

## When to Use

| Task | Script |
|------|--------|
| Run any GraphQL query | `graphql.sh` |
| Find repos by keyword/topic/language | `search_repos.sh` |
| Get full details on a repo | `repo_info.sh` |
| Look up a user or org | `user_info.sh` |
| List an org's repositories | `org_repos.sh` |
| Find issues or PRs | `search_issues.sh` |
| Check rate limit before bulk work | `rate_limit.sh` |

## References

- [`references/graphql_patterns.md`](references/graphql_patterns.md) — Common query patterns, pagination, fragments, error handling
- [GitHub GraphQL Explorer](https://docs.github.com/en/graphql/overview/explorer)
- [GitHub GraphQL API Docs](https://docs.github.com/en/graphql)

## Contributing

1. Scripts live in `scripts/` and source `_common.sh` for shared helpers
2. Every script must support `--help` and `--json`
3. Test with `gh auth status` before submitting changes
