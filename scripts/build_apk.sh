#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required. Install Flutter and Android SDK, then rerun this script." >&2
  exit 1
fi

if [[ ! -d android ]]; then
  flutter create --project-name imtahan_hazirligi --org az.edu --platforms android .
fi

PUBSPEC_VERSION="$(sed -n 's/^version: *//p' pubspec.yaml | head -n 1)"
APP_VERSION="${APP_BUILD_NAME:-${PUBSPEC_VERSION%%+*}}"
DEFAULT_BUILD_NUMBER="${PUBSPEC_VERSION##*+}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}"

if [[ ! "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "APP_BUILD_NAME must be a semantic version such as 1.0.0." >&2
  exit 1
fi

if [[ ! "$APP_BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  echo "APP_BUILD_NUMBER must be a positive integer." >&2
  exit 1
fi

flutter pub get
flutter build apk --release \
  --build-name="$APP_VERSION" \
  --build-number="$APP_BUILD_NUMBER"

mkdir -p site/downloads
VERSIONED_APK="imtahan-hazirligi-v${APP_VERSION}-build${APP_BUILD_NUMBER}.apk"
cp build/app/outputs/flutter-apk/app-release.apk "site/downloads/$VERSIONED_APK"
cp build/app/outputs/flutter-apk/app-release.apk site/downloads/imtahan-hazirligi.apk
printf '{\n  "version": "%s",\n  "buildNumber": %s,\n  "filename": "%s"\n}\n' \
  "$APP_VERSION" "$APP_BUILD_NUMBER" "$VERSIONED_APK" > site/downloads/latest.json
echo "APK copied to site/downloads/$VERSIONED_APK and site/downloads/imtahan-hazirligi.apk"
