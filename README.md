# github-graphql-api-skill

> Drop-in skill for AI agents to query GitHub's GraphQL API.

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)
![gh CLI](https://img.shields.io/badge/Requires-gh%20CLI-black.svg)

GitHub's GraphQL API is incredibly powerful for searching and discovering things on GitHub — way beyond what REST gives you. A single query can search repos by language, stars, and topics, pull contributor counts, check recent releases, and get issue stats all at once.

I built this because I use it daily with my AI agents to find relevant repositories, open source projects, SDKs, MCP servers, and other agent skills. Instead of manually browsing GitHub, I just ask my agent and it uses these scripts to find exactly what I need.

## Install

### Tell your AI agent

Just say something like:

> Add the GitHub GraphQL skill from https://github.com/pvoo/github-graphql-api-skill as a submodule in my skills directory

### Manual

**Git submodule (recommended):**
```bash
# Pick wherever your agent reads skills from
git submodule add https://github.com/pvoo/github-graphql-api-skill .claude/skills/github-graphql
git submodule add https://github.com/pvoo/github-graphql-api-skill skills/github-graphql
```

**Or just clone it:**
```bash
git clone https://github.com/pvoo/github-graphql-api-skill skills/github-graphql
```

### Prerequisites

- **[gh CLI](https://cli.github.com/)** — installed and authenticated (`gh auth login`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **Bash 4+**

## How it works

Your agent reads `SKILL.md`, sees what scripts are available, and calls them based on what you ask. You get human-readable output or structured JSON.

```
You: "Find popular Python ML repos with 1000+ stars"
  → Agent runs: scripts/search_repos.sh "machine learning" --language python --stars ">1000"
  → You get results
```

Works with Claude Code, Codex, Gemini CLI, Cursor, Windsurf, and anything else that reads skill files. Also works standalone from the terminal.

## Scripts

| Script | What it does |
|--------|-------------|
| [`graphql.sh`](scripts/graphql.sh) | Run any GraphQL query (inline or from file) |
| [`search_repos.sh`](scripts/search_repos.sh) | Search repos by keyword, language, stars, topic |
| [`repo_info.sh`](scripts/repo_info.sh) | Full details on a repo (stars, forks, languages, releases) |
| [`user_info.sh`](scripts/user_info.sh) | User or org profile |
| [`org_repos.sh`](scripts/org_repos.sh) | List an org's repos with sorting/filtering |
| [`search_issues.sh`](scripts/search_issues.sh) | Search issues and PRs |
| [`rate_limit.sh`](scripts/rate_limit.sh) | Check your API rate limit |

All scripts support `--help` and `--json`.

## Examples

```bash
# Find MCP servers in TypeScript
scripts/search_repos.sh "mcp server" --language typescript --stars ">50"

# What does this repo look like?
scripts/repo_info.sh microsoft/vscode

# Who's behind this org?
scripts/user_info.sh github

# Any open memory leak issues in Next.js?
scripts/search_issues.sh "memory leak" --repo vercel/next.js --type issue --state open

# Custom query — go wild
scripts/graphql.sh -q '{ viewer { login repositories(first: 5) { nodes { name stargazerCount } } } }'
```

**Output:**
```
⭐ 47123 | upstash/context7 [TypeScript]
         Context7 MCP Server -- Up-to-date code documentation for LLMs
         Topics: llm, mcp, mcp-server
⭐ 27811 | microsoft/playwright-mcp [TypeScript]
         Playwright MCP server
         Topics: mcp, playwright
```

Add `--json` to any command for structured output your agent can parse.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `GH_TOKEN` | Alternative to `gh auth login` |
| `GH_HOST` | For GitHub Enterprise |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Paul van Oorschot
