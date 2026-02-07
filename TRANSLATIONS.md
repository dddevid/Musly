# 🌍 Translations / Traduzioni / Übersetzungen

Musly supports 24 languages thanks to our amazing community of translators!

## 📝 How to Contribute Translations

We use [Crowdin](https://crowdin.com/project/musly) to manage translations. It's easy and free!

### Steps to Contribute:

1. **Visit our Crowdin project**: https://crowdin.com/project/musly
2. **Sign up** for a free Crowdin account (or log in)
3. **Select your language** from the list
4. **Start translating!** Click on any string and enter your translation

### Supported Languages

- 🇺🇸 English (en) - Base language
- 🇦🇱 Albanian (sq)
- 🇮🇹 Italian (it)
- 🇧🇩 Bengali (bn)
- 🇨🇳 Chinese Simplified (zh)
- 🇩🇰 Danish (da)
- 🇫🇮 Finnish (fi)
- 🇫🇷 French (fr)
- 🇩🇪 German (de)
- 🇬🇷 Greek (el)
- 🇮🇳 Hindi (hi)
- 🇮🇩 Indonesian (id)
- 🇮🇪 Irish (ga)
- 🇳🇴 Norwegian (no)
- 🇵🇱 Polish (pl)
- 🇵🇹 Portuguese (pt)
- 🇷🇴 Romanian (ro)
- 🇷🇺 Russian (ru)
- 🇪🇸 Spanish (es)
- 🇸🇪 Swedish (sv)
- 🇮🇳 Telugu (te)
- 🇹🇷 Turkish (tr)
- 🇺🇦 Ukrainian (uk)
- 🇻🇳 Vietnamese (vi)

## 🔄 Translation Workflow

1. **Source strings** are defined in `lib/l10n/app_en.arb`
2. **GitHub Action** automatically syncs with Crowdin when changes are pushed
3. **Translators** work on Crowdin to translate strings
4. **Translations** are automatically pulled back via GitHub Action and create a Pull Request
5. **Maintainers** review and merge the PR
6. **Users** get new translations in the next release!

## 🚀 For Developers

### Adding New Strings

1. Add new strings to `lib/l10n/app_en.arb`:

```json
{
  "myNewString": "Hello World",
  "@myNewString": {
    "description": "A friendly greeting"
  }
}
```

2. Run `flutter pub get` to generate the code

3. Use in your Dart code:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In your widget:
Text(AppLocalizations.of(context)!.myNewString)
```

### Strings with Parameters

```json
{
  "welcome": "Welcome, {name}!",
  "@welcome": {
    "description": "Welcome message with user name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

Usage:
```dart
Text(AppLocalizations.of(context)!.welcome('John'))
```

### Plurals

```json
{
  "songsCount": "{count, plural, =0{No songs} =1{1 song} other{{count} songs}}",
  "@songsCount": {
    "description": "Songs count with plural support",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

Usage:
```dart
Text(AppLocalizations.of(context)!.songsCount(5))
```

## 📋 Translation Guidelines

- **Be concise**: Mobile screens have limited space
- **Stay consistent**: Use the same terminology throughout
- **Keep the tone**: Match the friendly, casual tone of the app
- **Test context**: Some strings may appear in buttons, titles, or messages
- **Ask questions**: If a string is unclear, ask in the Crowdin comments!

## 🎯 Translation Priorities

1. **High Priority**: UI labels, buttons, navigation, error messages
2. **Medium Priority**: Settings, descriptions, tooltips
3. **Low Priority**: Advanced features, rarely-seen messages

## 🏆 Top Contributors

A big thank you to our translation contributors! Your work makes Musly accessible to millions of users worldwide.

Visit [Crowdin](https://crowdin.com/project/musly) to see our top contributors.

## ❓ Questions?

- **Translation questions**: Use Crowdin comments on specific strings
- **Technical questions**: Open an [issue on GitHub](https://github.com/dddevid/Musly/issues)
- **General discussion**: Join our [Discord](https://discord.gg/k9FqpbT65M)

---

Made with ❤️ by the Musly community
