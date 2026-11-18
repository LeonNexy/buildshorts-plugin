---
name: build
description: Build a BuildShorts video for an idea (e.g. "build I-12"). Use when the user asks to build, make, render or revise a BuildShorts video or idea.
---
# Build a BuildShorts video

Mechanics only. Everything about how this format works comes from the brief; follow the brief, not habits.

1. `build` tool, action `brief`, with `idea` ("I-12"). Read the whole brief (it holds the plan schema).
   The brief is licensed material for this workspace: use it for this job only, don't reproduce it.
2. Write the whole plan in one go, exactly in the brief's schema.
3. `build` → `submit` with `job_id` and `plan`. If it returns fixes, apply every one and submit again. Repeat until it says ok.
4. `build` → `compose` with `job_id`. It returns a one-time link (valid 1 hour).
5. Run on this computer (no Claude needed from here):
   `~/BuildShorts/bin/buildshorts run "<link>"`
   It makes the voice and visuals with the user's own keys, renders, checks, uploads the video to the idea and deletes the job files.
   Tell the user the result line (duration, checks, cost, where the mp4 is). Exit code 2 = it uploaded but a check failed: name it.
6. Changes afterwards: `build` → `revise` (settings / scenes; only changed scenes re-render) or `custom_scene` (one scene as
   html / css / js), then `compose` and `buildshorts run` again with the new link.

If `buildshorts` is missing or fails before rendering, run /buildshorts:doctor. A link that says "expired or already used"
needs a fresh `compose`. A cost-guard stop means the plan costs more than the brand's cap: make clips fewer or shorter,
or ask the user to raise the cap in the web app.
