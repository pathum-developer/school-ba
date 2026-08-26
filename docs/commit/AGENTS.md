# Commit Guidance

These rules apply when the user asks for a commit or related Git work.

- If the user explicitly asks to keep commented code, preserve those comments unless they are invalid syntax or break compilation.
- If the user explicitly asks to commit changes as-it-is, do not normalize, clean up, or refactor the file contents first; commit the current working-tree state for the requested files.
- If a method contains a `TODO` comment, do not change that method unless the user explicitly asks for it.
- If the user provides a quoted commit comment, correct grammar and spelling first, then use the corrected text as the git commit message.
