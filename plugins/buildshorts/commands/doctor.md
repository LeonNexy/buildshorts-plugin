---
description: Check this computer for BuildShorts (tools, HyperFrames / Chrome, keys, Claude sign-in, disk) and report it
allowed-tools: Bash
---
Run `~/BuildShorts/bin/buildshorts doctor` and report the result: one line per ✗ with its fix (the output has a → hint).
The result also goes to the web app (key names only). If `~/BuildShorts/bin/buildshorts` doesn't exist, run /buildshorts:setup.
For a failed tool, rerun the matching setup step: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" tools` or `… runner`.
