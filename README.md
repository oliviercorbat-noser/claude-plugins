# claude-plugins

A personal [Claude Code](https://claude.com/claude-code) plugin marketplace. It bundles plugins that add custom skills (and, in the future, agents/commands) to Claude Code via the standard plugin format.

## Installing this marketplace

Add the marketplace to Claude Code, then install whichever plugins you want from it:

```
/plugin marketplace add OlivierCorbat/claude-plugins
/plugin install GitHub-plugin
/plugin install my-first-plugin
```

(Replace the marketplace source with a local path if you're working from a clone, e.g. `/plugin marketplace add C:\Work\Projects\claude-plugins`.)

## Plugins

| Plugin | Description | Skills |
|---|---|---|
| [`GitHub-plugin`](plugins/github-plugin) | Interact with GitHub repositories, issues, and pull requests through the GitHub MCP server. | `branch-and-push`, `commit` |
| [`my-first-plugin`](plugins/my-first-plugin) | A minimal example/learning plugin. | `hello` |

### GitHub-plugin

Source: [`plugins/github-plugin`](plugins/github-plugin)

Connects Claude Code to GitHub via the [GitHub MCP server](https://api.githubcopilot.com/mcp/) (configured in `.mcp.json`). Requires a `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable with access to the target repositories.

**Skills:**

- **`commit`** — Inspects staged/unstaged changes, drafts a [Conventional Commits](https://www.conventionalcommits.org/) message, optionally asks for an Epic/Ticket number to prefix the message with (`<Epic>/<Ticket> <type>(<scope>): <description>`), and commits locally.
- **`branch-and-push`** — End-to-end workflow: asks for a branch description (and optional Epic/Ticket numbers), creates a local branch named `<epic>/<ticket>-<slug>` (omitting empty parts), commits the current changes as a conventional commit, creates the branch and pushes the commit through the GitHub MCP server (`create_branch` / `push_files`), wires up the local tracking branch, and opens a draft pull request (`create_pull_request`).

### my-first-plugin

Source: [`plugins/my-first-plugin`](plugins/my-first-plugin)

A barebones example plugin used to learn the plugin format.

**Skills:**

- **`hello`** — Greets the user warmly and asks how it can help. Model-invocation is disabled (`disable-model-invocation: true`), so it only runs when explicitly invoked.

## Repository layout

```
.claude-plugin/marketplace.json   # marketplace manifest listing all plugins
plugins/
  <plugin-name>/
    .claude-plugin/plugin.json    # plugin manifest (name, description, version, author)
    .mcp.json                     # MCP servers the plugin registers (if any)
    agents/                       # custom agents (currently unused by either plugin)
    commands/                     # custom slash commands (currently unused by either plugin)
    skills/
      <skill-name>/SKILL.md       # skill definition (frontmatter + instructions)
    README.md
```

## Adding a new plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `description`, `version`, and `author`.
2. Add any `skills/<skill-name>/SKILL.md`, `agents/`, or `commands/` the plugin needs.
3. If the plugin talks to an external service, declare it in `plugins/<name>/.mcp.json`.
4. Register the plugin in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) with its `name`, `source`, and `description`.

## License

[MIT](LICENSE) © Olivier Corbat
