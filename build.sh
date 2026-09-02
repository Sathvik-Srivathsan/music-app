#!/usr/bin/env bash
# Vercel build script for the Flutter web app.
# Build Command in Vercel:  ./build.sh      (or:  bash build.sh)
# Env vars SUPABASE_URL / SUPABASE_ANON_KEY come from Vercel Environment
# Variables and are passed into the Flutter build as --dart-define (the only
# way compile-time String.fromEnvironment values can be reached in a web build).
set -e

# Install Flutter (stable) into $HOME if not already present. `|| true` keeps
# the clone idempotent across redeploys (the folder persists between builds).
git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$HOME/flutter" || true
export PATH="$PATH:$HOME/flutter/bin:$HOME/flutter/bin/cache/dart-sdk/bin"

flutter config --no-analytics
flutter pub get

flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
