#!/usr/bin/env bash
# Vercel build script for the Flutter web app.
# Invoked by repository vercel.json:  "buildCommand": "bash build.sh"
# Env vars SUPABASE_URL / SUPABASE_ANON_KEY come from Vercel Environment
# Variables and are passed into the Flutter build as --dart-define (the only
# way compile-time String.fromEnvironment values can be reached in a web build).
#
# Vercel makes its env vars available to any build command, so $SUPABASE_URL
# and $SUPABASE_ANON_KEY are already set in this shell's environment at build
# time. We simply forward them to --dart-define below.
set -e

# Fail fast with a clear message if the env vars did not reach the build step.
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERROR: SUPABASE_URL / SUPABASE_ANON_KEY are missing from the build environment."
  echo "Add them in Vercel: Project -> Settings -> Environment Variables ->"
  echo "SUPABASE_URL and SUPABASE_ANON_KEY (scoped to Production)."
  exit 1
fi

# Make this script robust to whatever working directory Vercel starts the build
# from: cd to the directory that actually contains this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Install Flutter (stable) into $HOME if not already present. `|| true` keeps
# the clone idempotent across redeploys (the folder persists between builds).
git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$HOME/flutter" || true
export PATH="$PATH:$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin"

flutter config --no-analytics
flutter pub get

flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
