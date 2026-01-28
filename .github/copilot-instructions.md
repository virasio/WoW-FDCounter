# Copilot Instructions for FDCounter

## Language

- All code, comments, commit messages, and documentation must be in **English**.
- Variable names, function names, and identifiers must be in English.

## Pre-commit Updates

- Update `README.md` **before each commit** when new features are added.
- Keep the README concise and user-focused.
- Update `.github/plan.md` **before each commit** to reflect current progress.

## Commit Messages

- Use clear, descriptive commit messages in English.
- First line: describe what was done functionally.
- Additional lines (if needed): functional details, not technical implementation.

## Code Style

- Use consistent indentation (4 spaces for Lua).
- Add comments for non-obvious logic.
- Keep functions focused and reasonably sized.

## WoW Addon Specifics

- Target Interface version: `120000` (Midnight 12.0.0)
- Use WoW API best practices.
- Handle events properly with frame:RegisterEvent/SetScript pattern.

## File Paths

- Never store personal file paths (like WoW installation directory) in the repository.
- Use relative paths where possible.
