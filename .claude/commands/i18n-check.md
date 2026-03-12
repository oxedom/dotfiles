# Frontend i18n Synchronization

This command runs the i18n synchronization script located at `packages/frontend-my-training-app/scripts/i18n-sync.js`.

The script synchronizes internationalization dictionary files by:

1. Building a master key structure from all source files.
2. Adding missing keys with `MISSING-KEY-{index}` values.
3. Preserving identical key ordering across all files.
4. Supporting nested object structures.
5. Never removing existing keys or values.

## Usage

To run the i18n synchronization script, use the following command in the root of the project:

```bash
node packages/frontend-my-training-app/scripts/i18n-sync.js
```

This will process the dictionary files located in `packages/frontend-my-training-app/src/i18n/dictionary`.
