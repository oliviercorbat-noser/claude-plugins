---
name: branch-and-push
description: Creates a new git branch named <epic>/<ticket>-<branch-name> (omitting empty parts), commits the current changes as a conventional commit, pushes the commit via the GitHub MCP server, and opens a draft pull request. Use when the user wants to start a new branch, asks to "branch and push", or wants a branch+commit+push+draft-PR done through the GitHub MCP server.
---

# Branch and Push

## Workflow

1. **Ask for the branch description** (single prompt):

   > What should the branch be called? (a short kebab-case description, e.g. `add-stadium-endpoint`)

   Slugify the answer: lowercase, spaces/underscores → `-`, strip any character that isn't `a-z0-9-`.

2. **Ask for the Epic number** (separate prompt, after the branch name is known):

   > What is the Epic number? (leave blank to skip)

3. **Ask for the Ticket number** (separate prompt, after the Epic question):

   > What is the Ticket number? (leave blank to skip)

   Ask these one at a time, not combined — do not merge steps 2 and 3 into one question.

4. **Compose the full branch name** from the slug (`<slug>`) and the answers:

   | Epic | Ticket | Branch name |
   |---|---|---|
   | yes | yes | `<epic>/<ticket>-<slug>` |
   | yes | no | `<epic>/<slug>` |
   | no | yes | `<ticket>-<slug>` |
   | no | no | `<slug>` |

   The `/` gives the folder structure in Git UI tools (GitKraken, Fork, etc.); `-` separates the ticket from the description since `:` is not a valid character in git refs.

5. **Create the local branch** from the current HEAD:

   ```powershell
   git checkout -b <branch-name>
   ```

6. **Draft a conventional commit message** for the current changes (no epic/ticket prefix — that information already lives in the branch name):

   ```
   <type>(<scope>): <short imperative description>
   ```

   | type | when |
   |------|------|
   | `feat` | new feature or capability |
   | `fix` | bug fix |
   | `docs` | documentation only |
   | `refactor` | code restructure, no behavior change |
   | `chore` | build, deps, tooling, config |
   | `test` | adding or updating tests |
   | `ci` | CI/CD pipeline changes |
   | `perf` | performance improvement |
   | `style` | formatting, no logic change |

   - Inspect `git status` / `git diff --staged` (fall back to `git diff HEAD` if nothing staged) to decide type, scope, and description.
   - `scope` is the affected module/folder — omit if the change spans many areas.
   - Description: lowercase, imperative mood, no trailing period, ≤72 chars total.
   - If nothing is staged, `git add -A` first so the commit captures all current changes.

7. **Commit locally**:

   ```powershell
   git commit -m @'
   <type>(<scope>): <description>

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   '@
   ```

8. **Resolve `owner`/`repo`** from the remote URL (needed for the MCP calls):

   ```powershell
   git remote get-url origin
   ```

   Parse `owner/repo` from either form: `https://github.com/<owner>/<repo>.git` or `git@github.com:<owner>/<repo>.git`.

9. **Create the branch on GitHub** via the MCP server (base it off the repo's default branch unless told otherwise):

   ```
   mcp__github__create_branch(owner, repo, branch=<branch-name>, from_branch=<default branch>)
   ```

   If the branch already exists remotely, tell the user and ask whether to reuse it or pick a different name — do not silently overwrite.

10. **Push the commit via the GitHub MCP server** (not `git push`). Collect the files changed in the commit just made (`git show --name-only --diff-filter=ACMR <commit-sha>`) and their current content, then:

    ```
    mcp__github__push_files(owner, repo, branch=<branch-name>, files=[{path, content}, ...], message=<same commit message used in step 7, including the Co-Authored-By line>)
    ```

    `push_files` can only add/modify files — it cannot delete them. If the commit deletes files, tell the user those deletions won't be reflected on GitHub by this tool and will need a regular `git push` or a follow-up fix.

11. **Wire up local tracking** so future plain `git push`/`git pull` work on this branch:

    ```powershell
    git branch --set-upstream-to=origin/<branch-name>
    ```

12. **Open a draft pull request** via the GitHub MCP server:

    ```
    mcp__github__create_pull_request(owner, repo, title=<PR title>, head=<branch-name>, base=<default branch>, draft=true, body=<PR body>)
    ```

    - **Title**: `<epic>/<ticket> <description>` when either was provided (capitalize the description), otherwise just the capitalized description — e.g. `EPIC3/T-17 Add stadium endpoint`. This is where the epic/ticket reference gets surfaced for reviewers, since the commit message itself stays prefix-free.
    - **Body**: a short paragraph summarizing the change (derived from the diff, same source used to draft the commit message), ending with:

      ```
      🤖 Generated with [Claude Code](https://claude.com/claude-code)
      ```

13. **Report back**: the branch name, the local commit hash (short), confirmation that `push_files` succeeded, and the draft PR URL/number from the MCP response.

## Notes

- Steps 2–3 must be asked sequentially, never combined into a single question — the user wants to answer Epic and Ticket one after another.
- Never invent an Epic or Ticket number; leave the corresponding segment out entirely when the user leaves it blank.
- Never use `--no-verify` or bypass commit signing.
