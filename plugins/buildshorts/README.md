# BuildShorts for Claude Code

Connects Claude Code to [BuildShorts](https://buildshorts.com) and installs the local runner that renders your short
videos (Reels, TikTok, YouTube Shorts) on this computer with your own provider keys.

```
/plugin marketplace add LeonNexy/buildshorts-plugin
/plugin install buildshorts@buildshorts
/buildshorts:setup
```

- `/buildshorts:setup`: installs Node, ffmpeg, whisper-cli, yt-dlp and the signed runner into `~/BuildShorts`, adds the
  BuildShorts connector, saves your optional keys (macOS Keychain / a private file) and checks the computer.
- `/buildshorts:status`, `/buildshorts:doctor`, `/buildshorts:update`.
- Recipes: "build I-12" (brief → plan → submit → compose → `buildshorts run`), and fetching YouTube references locally.

Keys never leave this computer except to the provider they belong to. The runner itself is downloaded by setup as a
signed bundle with your BuildShorts token; it is not part of this repository.
