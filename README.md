# github-graphql

> Shell scripts for querying GitHub's GraphQL API v4 via the `gh` CLI.

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)
![gh CLI](https://img.shields.io/badge/Requires-gh%20CLI-black.svg)

Search repos, inspect repositories, look up users/orgs, search issues/PRs, run arbitrary GraphQL queries, and monitor rate limits — all from the command line with human-readable and JSON output.

## Prerequisites

- **[gh CLI](https://cli.github.com/)** — installed and authenticated (`gh auth login`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **Bash 4+**

## Install

```bash
git clone https://github.com/pvoo/github-graphql.git
cd github-graphql

# Option A: Add to PATH
export PATH="$PWD/scripts:$PATH"

# Option B: Run directly
./scripts/search_repos.sh "your query"
```

## Quick Start

```bash
# Search for popular TypeScript GraphQL libraries
./scripts/search_repos.sh "graphql client" --language typescript --stars ">100"

# Get detailed info about a repo
./scripts/repo_info.sh cli/cli

# Look up a user profile
./scripts/user_info.sh torvalds --json
```

## Scripts

| Script | Description |
|--------|-------------|
| [`graphql.sh`](scripts/graphql.sh) | Run arbitrary GraphQL queries with variable support |
| [`search_repos.sh`](scripts/search_repos.sh) | Search repositories by keyword, language, stars, topic |
| [`repo_info.sh`](scripts/repo_info.sh) | Detailed repository info (stars, forks, languages, releases) |
| [`user_info.sh`](scripts/user_info.sh) | User or organization profile lookup |
| [`org_repos.sh`](scripts/org_repos.sh) | List organization repositories with sorting/filtering |
| [`search_issues.sh`](scripts/search_issues.sh) | Search issues and PRs by query, state, labels |
| [`rate_limit.sh`](scripts/rate_limit.sh) | Check GraphQL API rate limit status |

All scripts support `--help` and `--json` flags.

## Output Examples

**Human-readable** (`search_repos.sh "neovim" --limit 2`):

```
 neovim/neovim ★ 84,521
   Vim-fork focused on extensibility and usability
   Language: C  Topics: vim, neovim, editor

 nvim-lua/kickstart.nvim ★ 21,340
   A launch point for your Neovim configuration
   Language: Lua  Topics: neovim, lua
```

**JSON** (`repo_info.sh cli/cli --json`):

```json
{
  "name": "cli",
  "owner": "cli",
  "stars": 38542,
  "forks": 6021,
  "language": "Go",
  "license": "MIT",
  "description": "GitHub's official command line tool"
}
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `GH_TOKEN` | Alternative to `gh auth login` |
| `GH_HOST` | GitHub Enterprise host |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Paul van Oorschot
