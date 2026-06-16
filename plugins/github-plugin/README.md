# GitHub-plugin

A plugin to interact with GitHub repositories, issues, and pull requests — branching,
committing, and opening pull requests through the GitHub MCP server instead of raw
`git push`.

## MCP server

`.mcp.json` registers a `github` MCP server backed by GitHub's hosted Copilot MCP
endpoint:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

Set a `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable with a token that has
repo access before using the skills below — the server reads it from the
environment, it is not stored in the repo. `.claude/settings.local.json` enables
the `github` MCP server for this plugin (`enabledMcpjsonServers`).

## Skills

### `commit`

Analyzes staged/unstaged changes and drafts a [Conventional Commits](https://www.conventionalcommits.org/)
message (`<type>(<scope>): <description>`). Asks for an Epic and Ticket number
in a single prompt and prefixes the message as `<Epic>/<Ticket> <message>`,
omitting whichever part was left blank. Commits locally with
`git commit` (no `--no-verify`).

Use when you want to commit, write a commit message, or ask for a conventional
commit.

### `branch-and-push`

End-to-end branch → commit → push → draft PR workflow that goes through the
GitHub MCP server instead of plain `git push`:

1. Asks for a branch description (slugified) and, separately, an Epic number
   and Ticket number — composing `<epic>/<ticket>-<slug>` (parts omitted if
   left blank).
2. Creates the local branch (`git checkout -b`) and a Conventional Commits
   message for the current changes.
3. Commits locally, then resolves `owner`/`repo` from `git remote get-url origin`.
4. Creates the branch on GitHub (`mcp__github__create_branch`) and pushes the
   commit's files (`mcp__github__push_files`) — note this can add/modify
   files but not delete them; deletions need a regular `git push`.
5. Sets local upstream tracking so future plain `git push`/`git pull` work.
6. Opens a draft pull request (`mcp__github__create_pull_request`) titled
   `<epic>/<ticket> <description>` and reports back the branch name, commit
   hash, and PR URL.

Use when you want to start a new branch, "branch and push", or get a
branch + commit + push + draft PR done through the GitHub MCP server.

## Requirements

- A `GITHUB_PERSONAL_ACCESS_TOKEN` with repo access, available in the
  environment running Claude Code.
- A `git` remote named `origin` pointing at the GitHub repository
  (`branch-and-push` parses `owner/repo` from it).
