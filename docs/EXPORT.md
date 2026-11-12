# Platform export

## Verified development export

Godot executable discovered: `/Users/mak/Downloads/Godot.app/Contents/MacOS/Godot`.
Version reported by that executable: `4.7.2.stable.official.ed1daf0bf`.
Matching Android templates: `~/Library/Application Support/Godot/export_templates/4.7.2.stable`.
SDK: `~/Library/Android/sdk`. Existing OpenJDK 17: `/opt/homebrew/opt/openjdk@17`.

Android: `com.vanthevor.salvagestack`, version 0.2.1, versionCode 4. Exported APK reports min SDK 24, target SDK 36, arm64-v8a. APK alignment/export/signature verification succeeded. No install/launch on a device was possible. Permission: VIBRATE only; internet disabled.

The included APK uses the same **development-only** signer as the 0.1.0 APK supplied in this conversation, so this update can preserve the existing installation and save data. It was not signed using any production key or Parcel Pilot identity. That temporary key is not included. A subsequent debug APK signed by a different key may require uninstalling this development build first, which deletes that installation's local saves. Preserve player data before changing signing identity for a real release.

## Editor setup

1. Install matching 4.7.2 export templates via Godot → Manage Export Templates if absent.
2. In Editor Settings → Export → Android, set Java SDK Path and Android SDK Path. The locations above were inspected on this Mac.
3. In Project → Export → Android, configure your own debug keystore (Godot can use its default development keystore). This project has no embedded private signing paths or credentials.
4. Export Debug to a chosen `.apk` location; the source preset defaults to `builds/SalvageStack-debug.apk`.
5. Install on a physical Android device, check portrait cutouts, navigation gestures, touch input, focus/background, sound, haptics, frame pacing and repeated rounds.

A Play release needs your release signing key, a Gradle/AAB setup, store listing/forms and policy review. None of these is claimed complete. Do not upload the supplied development APK as a production release.

## Monetisation

`scripts/commerce.gd` is the single boundary for future occasional interstitials and permanent Remove Ads. Configuration fields are empty, availability is false and purchase/restore methods return false. There is no fake entitlement, dummy success callback, visible nonfunctional purchase button or live ad request.

To integrate native services, choose a maintained Godot 4.7-compatible Android v2 plugin, configure a separate Salvage Stack app, use Google's development test identifiers until release, provide its own interstitial and Remove Ads product IDs, integrate verified billing/restore acknowledgement and regional consent, and validate on-device. Enable Gradle/native internet permissions only as needed by that implementation. The current project is not billing- or consent-ready.

No Parcel Pilot source or settings were used: a generic four-method unavailable boundary was sufficient without inspecting that project's private configuration.

## iOS path

The gameplay/UI/save/audio code has no Android dependency. A future iOS export can use `com.vanthevor.salvagestack`, but needs matching Godot iOS templates, Xcode, an Apple team/signing profile, an iOS export preset and device verification. iOS native monetisation must be configured separately. No iOS binary was exported in this session.

## Documentation checked during implementation

- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html
- https://docs.godotengine.org/en/stable/classes/class_displayserver.html

Checked 2026-11-10. Runtime/export results above come from the installed engine and exported manifest, not from assuming a documentation version matches the local installation.
