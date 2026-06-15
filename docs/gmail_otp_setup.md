# Gmail OTP auto-fill setup

The code for Gmail OTP auto-fill is included in the app, but Google Sign-In
will not work until the project has OAuth clients configured.

## What the feature does

- Adds a Gmail link/unlink button on the home app bar.
- Requests only Google Sign-In plus the Gmail read-only scope.
- Reads recent mail only when VTOP asks for an OTP.
- Searches only messages from `info1@vitap.ac.in`.
- Falls back to manual OTP entry if Gmail is not linked or no fresh OTP is found.

## Android setup

1. Open Google Cloud Console for the Firebase/Google project used by the app.
2. Enable the Gmail API.
3. Configure the OAuth consent screen.
4. Add the Gmail read-only scope:
   `https://www.googleapis.com/auth/gmail.readonly`
5. Add yourself as a test user while developing.
6. Create an Android OAuth client with:
   - Package name: `com.harsha.vitapstudentapp`
   - Debug SHA-1 for local builds
   - Release SHA-1/SHA-256 for Play Store builds

Current local debug keystore values:

- SHA-1: `2F:3B:15:70:F2:9B:9B:08:B8:9C:62:16:69:D1:CF:01:90:7E:BE:81`
- SHA-256: `C5:71:F5:81:BC:43:0C:83:4F:67:2F:B2:C0:A5:CF:82:BE:EB:A5:B6:FF:72:70:78:F6:78:5A:2F:B8:83:32:6F`
7. Download the updated `google-services.json`.
8. Replace `android/app/google-services.json`.
9. Run:

```sh
flutter clean
flutter pub get
```

If Google Sign-In fails with developer error code 10, the package name or
SHA certificate in the OAuth client does not match the APK you installed.

## iOS setup

1. Create an iOS OAuth client with bundle ID `com.harsha.vitapstudentapp`.
2. Download the updated `GoogleService-Info.plist`.
3. Replace `ios/Runner/GoogleService-Info.plist`.
4. Add the `REVERSED_CLIENT_ID` from that plist as a URL scheme in
   `ios/Runner/Info.plist`.

## Play Store note

Gmail read-only access is a restricted Google scope. For personal/testing use,
OAuth test users are usually enough. For a public Play Store release, Google may
require OAuth verification before normal users can link Gmail.
