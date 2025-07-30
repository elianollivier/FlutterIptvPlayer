# IPTV Stream Management


This project allows managing IPTV playlists.

## Customizing the App Icon

1. Add your icon images under `assets/icon/`.
2. Configure the `flutter_launcher_icons` package in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: true
  windows: true
  image_path: "assets/icon/app_icon.png"
```

3. Run `flutter pub run flutter_launcher_icons:main` to generate platform icons.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
