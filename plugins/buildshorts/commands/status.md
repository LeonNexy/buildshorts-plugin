---
description: Show BuildShorts status on this computer (runner version, keys, connector, last builds)
allowed-tools: Bash
---
Show where BuildShorts stands on this computer. Run these and summarise in at most 8 short lines:
- `~/BuildShorts/bin/buildshorts version`
- `~/BuildShorts/bin/buildshorts keys list` (names only)
- `~/BuildShorts/bin/buildshorts heartbeat` (tells the web app this computer is online, and whether a kit update exists)
- `ls -t ~/BuildShorts/out | head -5` (the latest finished videos)
If the runner is missing, suggest /buildshorts:setup. If an update is available, suggest /buildshorts:update.
