#!/usr/bin/env bash
set -euo pipefail

if [ ! -d /opt/buildhome/flutter ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/buildhome/flutter
fi

export PATH="$PATH:/opt/buildhome/flutter/bin"

flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=DANDI_BACKEND_URL="${DANDI_BACKEND_URL:-http://127.0.0.1:8000}"
