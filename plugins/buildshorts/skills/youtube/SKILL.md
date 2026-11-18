---
name: youtube
description: Fetch waiting YouTube references for the BuildShorts swipe file and transcribe them on this computer. Use when the user adds YouTube links to BuildShorts, asks to fetch / transcribe YouTube references, or swipe.youtube_pending lists waiting posts.
---
# YouTube references (fetched and transcribed locally)

BuildShorts never downloads YouTube on its server: this computer does it with yt-dlp and whisper, for free.

Run `~/BuildShorts/bin/buildshorts youtube --limit 5`.
For every waiting post it runs `swipe.youtube_pending` → yt-dlp (≤ 720p, under the 50 MB upload limit) → `swipe.upload_request`
→ PUT → `swipe.youtube_fulfil` (views, likes, caption, channel, date, length) → local whisper → `swipe.save_transcript`.
The downloaded video is deleted afterwards. Report one line per post (✓ title, words in the transcript, or ✗ reason).

A single local file: `~/BuildShorts/bin/buildshorts transcribe <file> [--lang de]` prints the transcript.
If yt-dlp or whisper is missing, run /buildshorts:doctor.
