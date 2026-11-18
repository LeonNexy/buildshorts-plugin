#!/usr/bin/env bash
# BuildShorts setup: installs everything into ~/BuildShorts, user-local, no sudo.
#   install.sh tools    Node 22 (if missing), ffmpeg, yt-dlp, whisper-cli + a small model
#   install.sh runner   the signed runner bundle (needs the BuildShorts token) + HyperFrames + Chrome for rendering
#   install.sh path     put ~/BuildShorts/bin on PATH (adds one marked line to ~/.zshrc / ~/.bashrc)
# Safe to run again: everything already there is kept. macOS, Linux and Windows (WSL2, Ubuntu).
set -euo pipefail

BS="${BUILDSHORTS_HOME:-$HOME/BuildShorts}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"; ARCH="$(uname -m)"
mkdir -p "$BS/bin" "$BS/models" "$BS/logs" "$BS/out" "$BS/library/music" "$BS/library/sfx" "$BS/versions"
export PATH="$BS/bin:$BS/node/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

say()  { printf '→ %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
fetch() { curl -fL --retry 3 --connect-timeout 20 -sS -o "$2" "$1"; }
sha256() { if have shasum; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

case "$OS" in Darwin) PLAT=darwin;; Linux) PLAT=linux;; *) echo "Unsupported system $OS (use macOS, Linux or Windows with WSL2)."; exit 1;; esac
case "$ARCH" in arm64|aarch64) A=arm64;; x86_64|amd64) A=x64;; *) echo "Unsupported CPU $ARCH"; exit 1;; esac
BREW=0; [ "$PLAT" = darwin ] && have brew && BREW=1

node_major() { node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0; }

install_node() {
  if have node && [ "$(node_major)" -ge 22 ]; then ok "Node $(node -v)"; return; fi
  say "Node 22 (user-local, ~/BuildShorts/node)"
  local sums file
  fetch "https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt" "$TMP/SHASUMS256.txt"
  file="$(grep -o "node-v22[.0-9]*-$PLAT-$A.tar.gz" "$TMP/SHASUMS256.txt" | head -1)"
  [ -n "$file" ] || { echo "No Node 22 build for $PLAT-$A"; exit 1; }
  fetch "https://nodejs.org/dist/latest-v22.x/$file" "$TMP/$file"
  [ "$(sha256 "$TMP/$file")" = "$(grep " $file\$" "$TMP/SHASUMS256.txt" | cut -d' ' -f1)" ] || { echo "Node download checksum mismatch"; exit 1; }
  rm -rf "$BS/node" && mkdir -p "$BS/node"
  tar -xzf "$TMP/$file" -C "$BS/node" --strip-components 1
  ok "Node $("$BS/node/bin/node" -v)"
}

install_ffmpeg() {
  if have ffmpeg && have ffprobe; then ok "$(ffmpeg -version | head -1 | cut -d' ' -f1-3)"; return; fi
  say "ffmpeg"
  if [ $BREW = 1 ]; then brew install ffmpeg >/dev/null
  elif [ "$PLAT" = darwin ]; then
    # static builds (LGPL/GPL, from ffmpeg.martin-riedl.de) when Homebrew isn't there
    local p; [ "$A" = arm64 ] && p=arm64 || p=amd64
    for t in ffmpeg ffprobe; do
      fetch "https://ffmpeg.martin-riedl.de/redirect/latest/macos/$p/release/$t.zip" "$TMP/$t.zip"
      unzip -o -q "$TMP/$t.zip" -d "$BS/bin" && chmod +x "$BS/bin/$t"
      xattr -d com.apple.quarantine "$BS/bin/$t" 2>/dev/null || true
    done
  else
    local p; [ "$A" = arm64 ] && p=arm64 || p=amd64
    fetch "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-$p-static.tar.xz" "$TMP/ff.tar.xz"
    tar -xJf "$TMP/ff.tar.xz" -C "$TMP"
    cp "$TMP"/ffmpeg-*-static/ffmpeg "$TMP"/ffmpeg-*-static/ffprobe "$BS/bin/" && chmod +x "$BS/bin/ffmpeg" "$BS/bin/ffprobe"
  fi
  have ffmpeg && ok "ffmpeg installed" || { echo "ffmpeg install failed"; exit 1; }
}

install_ytdlp() {
  if have yt-dlp; then ok "yt-dlp $(yt-dlp --version)"; return; fi
  say "yt-dlp"
  if [ $BREW = 1 ]; then brew install yt-dlp >/dev/null
  else
    local f; if [ "$PLAT" = darwin ]; then f=yt-dlp_macos; elif [ "$A" = arm64 ]; then f=yt-dlp_linux_aarch64; else f=yt-dlp_linux; fi
    fetch "https://github.com/yt-dlp/yt-dlp/releases/latest/download/$f" "$BS/bin/yt-dlp" && chmod +x "$BS/bin/yt-dlp"
    xattr -d com.apple.quarantine "$BS/bin/yt-dlp" 2>/dev/null || true
  fi
  have yt-dlp && ok "yt-dlp $(yt-dlp --version)" || warn "yt-dlp not installed (only needed for YouTube references)"
}

install_whisper() {
  if ! have whisper-cli; then
    say "whisper.cpp (local speech-to-text)"
    if [ $BREW = 1 ]; then brew install whisper-cpp >/dev/null
    elif have cmake && have git && { have cc || have gcc || have clang; }; then
      rm -rf "$BS/src/whisper.cpp" && mkdir -p "$BS/src"
      git clone --depth 1 --branch v1.7.6 https://github.com/ggml-org/whisper.cpp "$BS/src/whisper.cpp" >/dev/null 2>&1
      (cd "$BS/src/whisper.cpp" && cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF >/dev/null && cmake --build build -j --config Release --target whisper-cli >/dev/null)
      cp "$BS/src/whisper.cpp/build/bin/whisper-cli" "$BS/bin/" && rm -rf "$BS/src/whisper.cpp"
    else
      warn "whisper-cli skipped: install cmake, git and a C compiler (Ubuntu: sudo apt install build-essential cmake git), then run setup again. Only needed for YouTube transcripts and the word-check."
      return
    fi
  fi
  ok "whisper-cli"
  if ! ls "$BS/models"/ggml-*.bin >/dev/null 2>&1 && ! ls "$HOME/Library/Caches/hyperframes/whisper-models"/ggml-*.bin >/dev/null 2>&1; then
    say "whisper model ggml-base (148 MB, multilingual)"
    fetch "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" "$BS/models/ggml-base.bin.part" && mv "$BS/models/ggml-base.bin.part" "$BS/models/ggml-base.bin"
  fi
  ok "whisper model"
}

write_wrapper() {
  cat > "$BS/bin/buildshorts" <<EOF
#!/usr/bin/env bash
# BuildShorts runner (installed by /buildshorts:setup)
export PATH="$BS/bin:$BS/node/bin:\$PATH"
exec node "$BS/current/buildshorts.mjs" "\$@"
EOF
  chmod +x "$BS/bin/buildshorts"
  ln -sf "$BS/runtime/node_modules/.bin/hyperframes" "$BS/bin/hyperframes" 2>/dev/null || true
}

install_runner() {
  have node || { echo "Run install.sh tools first."; exit 1; }
  if [ -n "${BUILDSHORTS_KIT_SOURCE:-}" ]; then
    # Development: run the runner straight from a local checkout of buildshorts-kit.
    say "runner from $BUILDSHORTS_KIT_SOURCE (development)"
    mkdir -p "$BS/versions/dev"
    ln -sfn "$BUILDSHORTS_KIT_SOURCE/runner/kit" "$BS/versions/dev/kit"
    ln -sfn "$BUILDSHORTS_KIT_SOURCE/runner/sfx" "$BS/versions/dev/sfx"
    printf '#!/usr/bin/env node\nimport "%s/runner/bin/buildshorts.js";\n' "$BUILDSHORTS_KIT_SOURCE" > "$BS/versions/dev/buildshorts.mjs"
    ln -sfn "$BS/versions/dev" "$BS/current"
  else
    say "runner (signed bundle from BuildShorts)"
    node "$HERE/fetch-runner.mjs"
  fi
  write_wrapper
  "$BS/bin/buildshorts" install-runtime
  ok "runner $("$BS/bin/buildshorts" version)"
}

add_path() {
  local line="export PATH=\"$BS/bin:\$PATH\" # BuildShorts"
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    { [ -f "$rc" ] || [ "$(basename "$rc")" = ".$(basename "${SHELL:-bash}")rc" ]; } || continue
    grep -q '# BuildShorts$' "$rc" 2>/dev/null || printf '\n%s\n' "$line" >> "$rc"
  done
  ok "~/BuildShorts/bin is on PATH in new terminals"
}

case "${1:-all}" in
  tools) install_node; install_ffmpeg; install_ytdlp; install_whisper ;;
  runner) install_runner ;;
  path) add_path ;;
  all) install_node; install_ffmpeg; install_ytdlp; install_whisper; install_runner; add_path ;;
  *) echo "usage: install.sh tools|runner|path|all"; exit 1 ;;
esac
