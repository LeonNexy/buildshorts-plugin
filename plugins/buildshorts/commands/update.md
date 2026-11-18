---
description: Update the BuildShorts runner to the latest signed release (keeps the previous one for rollback)
allowed-tools: Bash
---
Run `~/BuildShorts/bin/buildshorts update`. It downloads the latest runner from buildshorts.com, checks its Ed25519 signature and
SHA-256 and switches to it; the previous version stays. Report "updated A → B" or "up to date".
If the user reports problems after an update: `~/BuildShorts/bin/buildshorts update --rollback`.
Never update while a build is running (`pgrep -f "buildshorts.mjs run"`); wait for it to finish.
Then run `~/BuildShorts/bin/buildshorts doctor` so the web app shows the new version.
