# BuildShorts plugin for Claude Code

Make short videos with [BuildShorts](https://buildshorts.com) and your own Claude: clone a viral format, get ideas, and
let your computer build the shorts.

```
/plugin marketplace add LeonNexy/buildshorts-plugin
/plugin install buildshorts@buildshorts
/buildshorts:setup
```

Setup installs everything into `~/BuildShorts` (no sudo): Node 22 if missing, ffmpeg, yt-dlp, whisper-cli and the
BuildShorts runner, downloaded as a signed bundle with your BuildShorts token (Settings → Connect Claude). Your provider
keys (ElevenLabs, OpenAI, Kie.ai, Gemini) stay on your computer: macOS Keychain or a private file.

Commands: `/buildshorts:setup`, `/buildshorts:status`, `/buildshorts:doctor`, `/buildshorts:update`.
Then say "build I-12" in Claude Code.

Plugin 0.1.2. See LICENSE.
