# github-graphql

> Drop-in AI agent skill for querying GitHub's GraphQL API v4.

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)
![gh CLI](https://img.shields.io/badge/Requires-gh%20CLI-black.svg)

Give your AI coding agent the ability to search repos, inspect projects, look up users/orgs, search issues/PRs, run arbitrary GraphQL queries, and check rate limits — with human-readable and JSON output.

## What is this?

A **skill** — a set of shell scripts + a `SKILL.md` that any AI coding agent can read and use. Your agent reads `SKILL.md`, understands what scripts are available, and calls them to interact with GitHub's GraphQL API.

Works with: **Claude Code** · **Codex** · **Gemini CLI** · **Cursor** · **Windsurf** · **Cline** · **Roo Code** · any agent that reads skill/instruction files.

## Install

### Ask your AI agent

Just tell your agent:

> Add the GitHub GraphQL skill from https://github.com/pvoo/github-graphql as a submodule in my skills directory

Or be more specific:

> Clone https://github.com/pvoo/github-graphql into .claude/skills/github-graphql and read its SKILL.md

### Manual install

**As a git submodule (recommended):**
```bash
# Claude Code
git submodule add https://github.com/pvoo/github-graphql .claude/skills/github-graphql

# Codex / generic agent
git submodule add https://github.com/pvoo/github-graphql skills/github-graphql

# OpenClaw
git submodule add https://github.com/pvoo/github-graphql .agent/skills/github-graphql
```

**As a simple clone:**
```bash
git clone https://github.com/pvoo/github-graphql .claude/skills/github-graphql
```

**Copy into existing skills directory:**
```bash
git clone https://github.com/pvoo/github-graphql /tmp/github-graphql
cp -r /tmp/github-graphql/{SKILL.md,scripts,references} your-project/skills/github-graphql/
```

### Prerequisites

- **[gh CLI](https://cli.github.com/)** — installed and authenticated (`gh auth login`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **Bash 4+**

## How it works

```
You: "Find popular Python ML repos with 1000+ stars"
        ↓
Agent reads SKILL.md → picks search_repos.sh
        ↓
Agent runs: scripts/search_repos.sh "machine learning" --language python --stars ">1000" --json
        ↓
Agent gets structured JSON → formats answer for you
```

The agent decides which script to call based on your request. `SKILL.md` tells it what's available and how to use each script.

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

## Examples

```bash
# Search for MCP servers with 50+ stars
scripts/search_repos.sh "mcp server" --language typescript --stars ">50"

# Get full details on a repo
scripts/repo_info.sh microsoft/vscode

# Look up an organization
scripts/user_info.sh github

# Search open issues with a label
scripts/search_issues.sh "memory leak" --repo vercel/next.js --type issue --state open

# Run a custom GraphQL query
scripts/graphql.sh -q '{ viewer { login repositories(first: 5) { nodes { name stargazerCount } } } }'
```

**Human-readable output:**
```
⭐ 47123 | upstash/context7 [TypeScript]
         Context7 MCP Server -- Up-to-date code documentation for LLMs
         Topics: llm, mcp, mcp-server
⭐ 27811 | microsoft/playwright-mcp [TypeScript]
         Playwright MCP server
         Topics: mcp, playwright
```

**JSON output** (with `--json`):
```json
[
  {
    "nameWithOwner": "upstash/context7",
    "description": "Context7 MCP Server",
    "stargazerCount": 47123,
    "primaryLanguage": "TypeScript",
    "url": "https://github.com/upstash/context7"
  }
]
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `GH_TOKEN` | Alternative to `gh auth login` |
| `GH_HOST` | GitHub Enterprise host |

## Standalone use

You don't need an AI agent — all scripts work directly from the terminal:

```bash
git clone https://github.com/pvoo/github-graphql.git
cd github-graphql
./scripts/search_repos.sh "your query"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Paul van Oorschot
