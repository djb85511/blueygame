# Bluey's Number Adventures

An evidence-based, text-free arithmetic game for preschoolers (ages 3–5),
built with Flutter and Riverpod.

## Gameplay

- **Home**: one large PLAY button.
- **Bingo's Toy Basket**: toys (bones or balls) appear in a basket; the child
  taps the matching number (1–5). Every button shows a numeral *and* matching
  dots, and is at least 60×60 pt.
- **Correct**: the button turns green and bounces, Bingo cheers, stars burst,
  and the next problem appears automatically after 3 seconds.
- **Incorrect**: the toys and the tapped button wiggle gently. No red screens,
  no "wrong" text, no negative sounds; the child simply tries again.

## Adaptive engine

| Band | Name | Skills |
| --- | --- | --- |
| 1 | Bingo's Band | Subitizing 1–3 → counting up to 5 |
| 2 | Bluey's Crew | Addition/subtraction ±1 within 1–5 |
| 3 | Heeler Family | Addition/subtraction ±2 within 1–5 |

Each band has 3 levels (level 1 eases in, level 2 introduces the other skill,
level 3 mixes them). 3 correct answers in a row → level up; 2 incorrect
answers in a row → level down, crossing band boundaries as needed. Progress
is saved with `shared_preferences`.

## Structure

```
lib/
├── core/          theme, constants, audio (synth/haptic fallback + mock)
├── domain/        UserProgress, MathProblem, AdaptiveEngine, StorageService
└── presentation/  Riverpod GameNotifier, custom-painted widgets, views
```

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
