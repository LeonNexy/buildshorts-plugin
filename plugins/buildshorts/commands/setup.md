---
description: Set up BuildShorts on this computer (tools, runner, connector, keys, check)
argument-hint: "[connector link or bs_ token]"
allowed-tools: Bash, Read
---
Set up BuildShorts on this computer. Mechanics only; keep the user informed in one short line per step, in their language.
Never print, echo or repeat a provider key. Never ask the user to paste a provider key into this chat.

1. **Tools** (Node 22 if missing, ffmpeg, yt-dlp, whisper-cli + a small model, all user-local in `~/BuildShorts`):
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" tools`
   It can take a few minutes. If a step fails, show the last lines and what the script suggests.

2. **Connector token.** If `$ARGUMENTS` holds a link like `https://buildshorts.com/api/mcp/c/bs_…` or a `bs_…` token, use it.
   Otherwise ask the user to open buildshorts.com → Settings → Connect Claude, create a token and paste the connector link here.
   Then add the connector for all projects (replace any older one):
   `claude mcp remove buildshorts --scope user 2>/dev/null; claude mcp add --transport http --scope user buildshorts https://buildshorts.com/api/mcp/c/<token>`
   Also save it for the runner: `printf '%s' '<token>' | ~/BuildShorts/bin/buildshorts keys set token --stdin` (after step 3 if the runner isn't there yet).

3. **Runner** (signed bundle, verified before it is unpacked; HyperFrames and Chrome for rendering):
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" runner && bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" path`

4. **Provider keys** (optional, the user's own; each one is used only from this computer):
   ElevenLabs (voice), OpenAI (pictures), Kie.ai (video clips, Nano Banana), Gemini (Nano Banana pictures).
   Ask which ones they have. For each:
   - macOS: run `~/BuildShorts/bin/buildshorts keys set <elevenlabs|openai|kie|gemini>`. A macOS dialog with a hidden field asks for
     the key and saves it in the Keychain. Tell the user to look for the dialog.
   - Linux / Windows (WSL): ask the user to copy the key and say "copied", then run
     `~/BuildShorts/bin/buildshorts keys set <name> --from-clipboard` (saved in `~/.config/buildshorts/keys.env`, chmod 600).
   Then `~/BuildShorts/bin/buildshorts keys list` shows which are saved (names only).
   Optional default voice: `~/BuildShorts/bin/buildshorts config set voice.defaultVoiceId <ElevenLabs voice id>`.

5. **Check and report**: `~/BuildShorts/bin/buildshorts doctor`. It sends the result to the web app (key names only, never keys),
   which now shows **Computer: online**. Explain any ✗ line in one sentence with its fix.

6. Finish with: "Ready. Pick an idea on buildshorts.com and say: build I-12." Mention that the connector tools load after
   restarting Claude Code (or /mcp).
