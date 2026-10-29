# İmtahan 90+

Flutter app for Azerbaijan grade 9 graduation-exam practice in Mathematics and English.

## App features

- Azerbaijani welcome flow and locally saved student name/progress.
- Math and English topic catalog, lessons, worked examples, and practice questions.
- After a wrong or timed-out answer, reteaching holds that topic until three consecutive micro-questions are answered correctly.
- Topic progression is locked in order within each subject. Mistakes are saved as topics to revisit.
- Starting a new topic offers a random review from weak topics; the backend can generate a fresh question, with a local question-bank fallback.
- The AI tutor accepts Mathematics and English questions, offers a short Azerbaijani lesson for relevant topics, and falls back to local explanations when the service is unavailable.
- Reading and text-based listening simulation are included. Listening currently has no audio playback.
- If the optional coach backend is unavailable, lessons and the local question bank remain available.

## Build an Android APK

Install Flutter and the Android SDK, then run:

```sh
bash scripts/build_apk.sh
```

The script generates the Android platform project if needed, builds a release APK, and copies both a stable download (`site/downloads/imtahan-hazirligi.apk`) and a versioned APK into `site/downloads/`. The version and Android build number can be set with `APP_BUILD_NAME` and `APP_BUILD_NUMBER`; otherwise, values from `pubspec.yaml` are used.

On every push to `main`, the GitHub Actions workflow uses its run number as the Android build number, publishes a versioned APK as a GitHub Release, and deploys the site with the latest APK link. The download page is published at `https://asysu.github.io/apk/` when GitHub Pages is enabled for this repository using GitHub Actions. APK releases are available from the repository's Releases page.

## Optional Gemini coach

The mobile app calls a server-side coach endpoint. Do not put Gemini API keys in the app, source control, or a public website: APK contents can be inspected. Configure the backend with server environment variables (never commit their values):

```sh
cd server
export GEMINI_API_KEY_1="..."
export GEMINI_API_KEY_2="..."
export GEMINI_API_KEY_3="..."
node server.mjs
```

The server tries configured keys in order and does not return keys to the app. If every key or the backend fails, the app uses its local explanation and question bank. It provides `/ask` and `/teach` for the AI tutor, as well as `/coach` and `/review-question`. Set `APP_ORIGIN` to the exact public app/site origin when deploying the backend; the default wildcard is suitable only for local development.

The GitHub Pages build reads the repository Actions variable `COACH_API_BASE_URL` when compiling the app. Point it at the separately deployed coach server; store Gemini keys only in that server's secret environment, never in the Pages variable.

To connect a release build to the backend:

```sh
COACH_API_BASE_URL="https://your-coach.example" ./scripts/build_apk.sh
```

Any API keys shared in chat or another public place should be revoked and replaced before use.
