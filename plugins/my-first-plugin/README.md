# my-first-plugin

A greeting plugin to learn the basics of building Claude Code plugins.

## Hooks

### Lint after edit (`PostToolUse` example)

`hooks/hooks.json` registers a `PostToolUse` hook on the `Write|Edit` matcher,
running `hooks/lint-after-edit.sh` every time Claude writes or edits a file.

The script:
- Reads the hook payload from stdin and pulls out `tool_input.file_path`.
- Picks a linter based on the file extension, only if it's installed:
  - `.js`/`.jsx`/`.ts`/`.tsx` → `eslint`
  - `.py` → `ruff` (falls back to `flake8`)
  - `.sh`/`.bash` → `shellcheck`
- Skips silently (exit `0`) for unsupported file types or when no matching
  linter is on `PATH` — this is meant as a learning example, not something
  that should fail your session because a tool isn't installed.
- If the linter reports problems, prints them and exits `2` so the findings
  are fed back to Claude as actionable context.

**Test the script directly** (no Claude Code session needed):

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"some/file.js"}}' \
  | bash hooks/lint-after-edit.sh
```

**Try it for real:** hooks are loaded when a Claude Code session starts, so
after adding or changing `hooks/hooks.json` you need to restart the session
(`exit` then `claude`) before the hook takes effect. Run `/hooks` to confirm
it's registered, then ask Claude to write or edit a file with a lint issue
and watch the feedback come back.
