# GitHub GraphQL Common Patterns

## Authentication
All queries use `gh api graphql` which handles auth automatically via `gh auth`.
Alternative: set `GH_TOKEN` env var.

## Basic Query
```bash
gh api graphql -f query='{ viewer { login } }'
```

## Variables
```bash
# String variable: -f
gh api graphql -f query='query($q: String!) { ... }' -f q="search term"

# Integer variable: -F
gh api graphql -f query='query($n: Int!) { ... }' -F n=10
```

## Search Types
- `REPOSITORY` — repos
- `ISSUE` — issues and PRs
- `USER` — users
- `DISCUSSION` — discussions

## Pagination (Cursor-Based)
```graphql
query($cursor: String) {
  search(query: "test", type: REPOSITORY, first: 10, after: $cursor) {
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes { ... on Repository { nameWithOwner } }
  }
}
```
Loop: pass `endCursor` as `$cursor` until `hasNextPage` is false.

## Filtering & Sorting

### Repository Search Qualifiers
Passed in the query string (not GraphQL variables):
- `language:python` — by language
- `stars:>100` or `stars:50..200` — star range
- `topic:mcp` — by topic
- `org:microsoft` — scope to org
- `created:>2024-01-01` — by creation date
- `pushed:>2024-06-01` — recently pushed
- `sort:stars`, `sort:updated` — sort order

### Issue/PR Search Qualifiers
- `repo:owner/name` — scope to repo
- `type:issue` or `type:pr`
- `state:open` or `state:closed`
- `is:merged` — merged PRs
- `label:"bug"` — by label
- `author:username` — by author
- `assignee:username` — by assignee
- `milestone:"v1.0"` — by milestone

### Sorting in Object Queries
```graphql
repositories(first: 10, orderBy: {field: STARGAZERS, direction: DESC})
```
Fields: `STARGAZERS`, `UPDATED_AT`, `PUSHED_AT`, `CREATED_AT`, `NAME`.

## Nested Queries
```graphql
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    issues(first: 5, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        title
        author { login }
        labels(first: 3) { nodes { name } }
        comments(first: 1) { nodes { body } }
      }
    }
  }
}
```

## Fragments
```graphql
fragment RepoFields on Repository {
  nameWithOwner
  description
  stargazerCount
  url
  updatedAt
  primaryLanguage { name }
  repositoryTopics(first: 5) { nodes { topic { name } } }
}

query {
  repository(owner: "cli", name: "cli") { ...RepoFields }
}
```

## Inline Fragments (Union Types)
```graphql
nodes {
  ... on Issue { __typename number title state }
  ... on PullRequest { __typename number title state merged }
}
```

## Error Handling
| Error type | Meaning | Action |
|------------|---------|--------|
| `RATE_LIMITED` | Rate limit exceeded | Wait or check `rate_limit.sh` |
| `NOT_FOUND` | Resource doesn't exist | Verify owner/name |
| `FORBIDDEN` | No access | Check auth scope |

Check for errors:
```bash
result=$(gh api graphql -f query="..." 2>&1)
if echo "$result" | jq -e '.errors' > /dev/null 2>&1; then
  echo "Error: $(echo "$result" | jq -r '.errors[0].message')" >&2
fi
```

## Rate Limits
```graphql
{ rateLimit { limit cost remaining resetAt } }
```
- GraphQL API: **5,000 points/hour**
- Each query costs 1+ points based on complexity
- Nested connections multiply cost
- Use `first: N` to limit result size and reduce cost

## Useful Patterns

### Get viewer info (who am I?)
```bash
gh api graphql -f query='{ viewer { login name email } }'
```

### Check if repo exists
```bash
gh api graphql -f query='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) { nameWithOwner }
}' -f owner=cli -f name=cli
```

### Get latest release
```bash
gh api graphql -f query='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    latestRelease { tagName publishedAt url }
  }
}' -f owner=cli -f name=cli
```
