# İmtahan 90+

Flutter app for Azerbaijan grade 9 graduation-exam practice in Mathematics and English.

## App features

- Azerbaijani welcome flow and locally saved student name/progress.
- Blue onboarding links open a scrollable privacy policy and terms panel.
- Math and English topic catalog, lessons, worked examples, and practice questions.
- After a wrong or timed-out answer, reteaching holds that topic until three consecutive micro-questions are answered correctly.
- Topic progression is locked in order within each subject. Mistakes are saved as topics to revisit.
- Starting a new topic offers a random review from weak topics; Gemini can create a fresh question when a personal API key is configured, with a local question-bank fallback.
- The AI tutor sends Mathematics and English questions directly to Gemini using an API key the student enters in the app. The key is stored in encrypted device storage (not on the app's server). Lessons include worked examples, common mistakes, and a practice question.
- Reading and text-based listening simulation are included. Listening currently has no audio playback.
- If Gemini is unavailable, its error is shown clearly; local lessons and the question bank remain available.

## Build an Android APK

Install Flutter and the Android SDK, then run:

```sh
bash scripts/build_apk.sh
```

The script generates the Android platform project if needed, builds a release APK, and copies both a stable download (`site/downloads/imtahan-hazirligi.apk`) and a versioned APK into `site/downloads/`. The version and Android build number can be set with `APP_BUILD_NAME` and `APP_BUILD_NUMBER`; otherwise, values from `pubspec.yaml` are used.

On every push to `main`, the GitHub Actions workflow uses its run number as the Android build number, publishes a versioned APK as a GitHub Release, and deploys the site with the latest APK link. The download page is published at `https://asysu.github.io/apk/` when GitHub Pages is enabled for this repository using GitHub Actions. APK releases are available from the repository's Releases page.

## Gemini AI tutor

On the tutor screen, enter a personal Gemini API key created in [Google AI Studio](https://aistudio.google.com/app/apikey). The key is stored in encrypted Android device storage and is not sent to this app's server. The app sends the key and the student's prompt directly to Google's Gemini API over HTTPS to generate a response. Google handles those requests under its own terms and privacy policy; do not include personal or sensitive information in prompts. The key can be changed or deleted from the tutor screen. Google API quotas or billing limits may apply.

The tutor answers specific Mathematics and English questions, and can create a mini-lesson with worked examples, common mistakes, and a self-check exercise. If Gemini is unavailable, the app reports the error rather than showing an unrelated generated-looking answer. Existing local lessons and question banks remain available offline.
