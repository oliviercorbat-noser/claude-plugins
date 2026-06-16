---
name: commit
description: Analyzes staged/unstaged changes in the current repo and generates a conventional commit message. Asks the user for an Epic number and Ticket number, then prefixes the message as "<Epic>/<Ticket> <message>" — omitting the prefix when no numbers are provided. Use when the user wants to commit, write a commit message, or asks for a conventional commit.
---

# Commit

## Workflow

1. **Inspect changes**
   - Run `git status` to see staged vs. unstaged files
   - Run `git diff --staged` (fall back to `git diff HEAD` if nothing staged)

2. **Draft the commit message** using conventional commits:

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

   - `scope` is the affected module/folder (e.g. `api`, `auth`, `bruno`) — omit if change spans many areas
   - Description: lowercase, imperative mood, no trailing period, ≤72 chars total

3. **Ask the user** (single prompt, both questions together):

   > What is the Epic number and Ticket number for this commit? (Leave blank to skip)

4. **Compose the final message**:
   - Both provided → `<Epic>/<Ticket> <type>(<scope>): <description>`
   - Only one provided → `<Epic> <type>(<scope>): <description>` or `<Ticket> <type>(<scope>): <description>`
   - Neither provided → `<type>(<scope>): <description>`

5. **Commit** using the message via heredoc (no `--no-verify`):

   ```powershell
   git commit -m @'
   <final message>

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   '@
   ```

6. Confirm success with the short commit hash.

## Example outputs

```
feat(api): add stadium endpoint
fix(services): handle null response from Zafronix API
WC26/API-42 feat(controllers): add group standings forwarding
EPIC3/T-17 chore: add .gitignore and initial commit
```
