# Contributing

Thanks for your interest in contributing!

## Adding a New Script

1. Create `scripts/your_script.sh`
2. Source shared helpers: `source "$SCRIPT_DIR/_common.sh"`
3. Implement `--help` with usage info and examples
4. Implement `--json` for structured JSON output
5. Add a file header:
   ```bash
   #!/usr/bin/env bash
   # Brief description of what this script does
   # MIT License — Copyright 2026 Paul van Oorschot
   ```

## Shell Best Practices

- Use `set -euo pipefail` (inherited from `_common.sh`)
- Run `shellcheck -x scripts/*.sh` before submitting
- Quote all variables
- Use `[[ ]]` over `[ ]`
- Handle errors with meaningful messages to stderr

## Testing

- Ensure `gh auth status` works before testing
- Test both human-readable and `--json` output
- Test `--help` output
- Test with edge cases (empty results, bad input)

## Submitting

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Run shellcheck
5. Open a pull request with a clear description
