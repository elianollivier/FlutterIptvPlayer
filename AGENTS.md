# AGENTS.md – consignes pour Codex

## Construire et tester
- Pour récupérer les dépendances : `flutter pub get`
- Pour analyser : `flutter analyze`
- Pour tester : `flutter test --coverage`

## Style
- Utiliser la null-safety.
- Pas de `print` dans la logique métier ; préférer `logger`.
- Organiser les fichiers selon `lib/src/{models,services,widgets,screens}`.
