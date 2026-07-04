#!/bin/bash
# Vercel's build image has no Flutter SDK, so this fetches one, then builds
# the web release. Configure SUPABASE_URL / SUPABASE_ANON_KEY as Environment
# Variables in the Vercel project settings — they're written into `.env`
# here so flutter_dotenv can read them at runtime (same as local dev).
set -e

cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
EOF

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:$(pwd)/flutter/bin"

flutter config --enable-web
flutter pub get
flutter build web --release
