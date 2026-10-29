#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required. Install Flutter and Android SDK, then rerun this script." >&2
  exit 1
fi

if [[ ! -d android ]]; then
  flutter create --project-name imtahan_hazirligi --org az.edu --platforms android .
fi

flutter pub get
if [[ -n "${COACH_API_BASE_URL:-}" ]]; then
  flutter build apk --release --dart-define="COACH_API_BASE_URL=${COACH_API_BASE_URL}"
else
  flutter build apk --release
fi

mkdir -p site/downloads
cp build/app/outputs/flutter-apk/app-release.apk site/downloads/imtahan-hazirligi.apk
echo "APK copied to site/downloads/imtahan-hazirligi.apk"
