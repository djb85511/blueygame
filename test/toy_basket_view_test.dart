import 'package:bluey_number_adventures/core/audio/audio_service.dart';
import 'package:bluey_number_adventures/core/constants/game_constants.dart';
import 'package:bluey_number_adventures/domain/services/storage_service.dart';
import 'package:bluey_number_adventures/presentation/providers/game_state_provider.dart';
import 'package:bluey_number_adventures/presentation/views/toy_basket_view.dart';
import 'package:bluey_number_adventures/presentation/widgets/count_object.dart';
import 'package:bluey_number_adventures/presentation/widgets/feedback_overlay.dart';
import 'package:bluey_number_adventures/presentation/widgets/number_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  Finder numberButton(int value) =>
      find.byKey(ValueKey('number-button-$value'));

  bool overlayVisible(WidgetTester tester) =>
      tester.widget<FeedbackOverlay>(find.byType(FeedbackOverlay)).visible;

  group('Touch targets', () {
    for (final surface in const [
      Size(800, 600),
      Size(320, 568),
      Size(1024, 768),
    ]) {
      testWidgets('every NumberButton is at least 60×60 pt on $surface', (
        tester,
      ) async {
        await pumpWithProviders(
          tester,
          const ToyBasketView(),
          surface: surface,
        );

        final buttons = find.byType(NumberButton);
        expect(buttons, findsNWidgets(5));

        for (final element in buttons.evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(
            size.width,
            greaterThanOrEqualTo(GameConstants.minTouchTarget),
          );
          expect(
            size.height,
            greaterThanOrEqualTo(GameConstants.minTouchTarget),
          );
        }

        // The tappable InkWell itself fills the full 60×60+ area.
        final inkWells = find.descendant(
          of: buttons,
          matching: find.byType(InkWell),
        );
        expect(inkWells, findsNWidgets(5));
        for (final element in inkWells.evaluate()) {
          final box = element.renderObject! as RenderBox;
          expect(
            box.size.width,
            greaterThanOrEqualTo(GameConstants.minTouchTarget),
          );
          expect(
            box.size.height,
            greaterThanOrEqualTo(GameConstants.minTouchTarget),
          );
        }

        // The home button also meets the minimum.
        final home = tester.getSize(find.byKey(ToyBasketView.homeButtonKey));
        expect(home.width, greaterThanOrEqualTo(GameConstants.minTouchTarget));
        expect(home.height, greaterThanOrEqualTo(GameConstants.minTouchTarget));

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('taps near a button corner still register', (tester) async {
      final container = await pumpWithProviders(tester, const ToyBasketView());
      final rect = tester.getRect(numberButton(3));
      await tester.tapAt(rect.topLeft + const Offset(4, 4));
      await tester.pump();
      expect(container.read(gameStateProvider).isCelebrating, isTrue);
      await tester.pump(GameConstants.autoAdvanceDelay);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('undersized NumberButton still renders at 60×60', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: NumberButton(value: 1, onPressed: () {}, size: 20),
          ),
        ),
      );
      final size = tester.getSize(find.byType(NumberButton));
      expect(size, const Size.square(GameConstants.minTouchTarget));
    });
  });

  group('Text-free layout', () {
    for (final problem in const [
      threeBones,
      twoPlusOneBalls,
      fiveMinusTwoBones,
    ]) {
      testWidgets(
        'only numerals are rendered as text for ${problem.operator}',
        (tester) async {
          await pumpWithProviders(
            tester,
            const ToyBasketView(),
            problems: [problem],
          );

          final texts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
              .toList();
          expect(texts, isNotEmpty);
          for (final text in texts) {
            expect(
              text,
              matches(RegExp(r'^[1-5]$')),
              reason: 'Gameplay must not depend on reading words',
            );
          }

          // Everything else painted as glyphs must be an icon, never words.
          for (final rich in tester.widgetList<RichText>(
            find.byType(RichText),
          )) {
            final plain = rich.text.toPlainText();
            final isIcon = rich.text.style?.fontFamily == 'MaterialIcons';
            expect(
              isIcon || RegExp(r'^[1-5]$').hasMatch(plain),
              isTrue,
              reason: 'Unexpected text "$plain"',
            );
          }
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }

    testWidgets('problem quantities are shown as drawn objects', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const ToyBasketView(),
        problems: [threeBones],
      );
      expect(find.byType(CountObject), findsNWidgets(3));
    });

    testWidgets('addition shows basket toys plus toys Bingo is holding', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const ToyBasketView(),
        problems: [twoPlusOneBalls],
      );
      expect(find.byType(CountObject), findsNWidgets(3));
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('subtraction fades the toys that leave', (tester) async {
      await pumpWithProviders(
        tester,
        const ToyBasketView(),
        problems: [fiveMinusTwoBones],
      );
      final faded = tester
          .widgetList<CountObject>(find.byType(CountObject))
          .where((o) => o.faded);
      expect(faded, hasLength(2));
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });
  });

  group('Interaction flow', () {
    testWidgets('correct tap celebrates then auto-advances after 3 seconds', (
      tester,
    ) async {
      final audio = MockAudioService();
      final container = await pumpWithProviders(
        tester,
        const ToyBasketView(),
        audio: audio,
      );

      expect(container.read(gameStateProvider).problem, threeBones);
      await tester.tap(numberButton(3));
      await tester.pump();

      final state = container.read(gameStateProvider);
      expect(state.isCelebrating, isTrue);
      expect(state.mood, CharacterMood.happy);
      expect(state.progress.streakCorrect, 1);
      expect(overlayVisible(tester), isTrue);
      expect(
        tester.widget<NumberButton>(numberButton(3)).feedback,
        NumberButtonFeedback.correct,
      );
      expect(audio.played, [SoundCue.success]);

      // Buttons are locked during the celebration.
      await tester.tap(numberButton(1), warnIfMissed: false);
      await tester.pump();
      expect(container.read(gameStateProvider).progress.streakIncorrect, 0);

      await tester.pump(const Duration(milliseconds: 2900));
      expect(container.read(gameStateProvider).problem, threeBones);

      await tester.pump(const Duration(milliseconds: 200));
      final next = container.read(gameStateProvider);
      expect(next.isCelebrating, isFalse);
      expect(next.problem, twoPlusOneBalls);
      expect(next.problemNumber, 1);
      expect(overlayVisible(tester), isFalse);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('incorrect tap wiggles gently and allows retry', (
      tester,
    ) async {
      final audio = MockAudioService();
      final container = await pumpWithProviders(
        tester,
        const ToyBasketView(),
        audio: audio,
      );

      await tester.tap(numberButton(1));
      await tester.pump();

      var state = container.read(gameStateProvider);
      expect(state.isCelebrating, isFalse);
      expect(state.lastIncorrectAnswer, 1);
      expect(state.wiggleCount, 1);
      expect(state.progress.streakIncorrect, 1);
      expect(state.mood, CharacterMood.encouraging);
      expect(overlayVisible(tester), isFalse);
      expect(
        tester.widget<NumberButton>(numberButton(1)).feedback,
        NumberButtonFeedback.tryAgain,
      );
      // No negative sound and no failure text.
      expect(audio.played, [SoundCue.gentleRetry]);
      expect(
        find.textContaining(RegExp('wrong|no|oops', caseSensitive: false)),
        findsNothing,
      );

      // Mid-wiggle, the object group is displaced horizontally only.
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
      await tester.pump(GameConstants.wiggleDuration);

      // Same problem stays; a retry with the right answer celebrates.
      expect(state.problem, threeBones);
      await tester.tap(numberButton(3));
      await tester.pump();
      state = container.read(gameStateProvider);
      expect(state.isCelebrating, isTrue);
      expect(state.lastIncorrectAnswer, isNull);
      await tester.pump(GameConstants.autoAdvanceDelay);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('two wrong taps level down; progress is persisted', (
      tester,
    ) async {
      final container = await pumpWithProviders(
        tester,
        const ToyBasketView(),
        prefs: {
          StorageService.progressKey:
              '{"band":2,"level":2,"streakCorrect":0,"streakIncorrect":0}',
        },
      );
      expect(container.read(gameStateProvider).progress.band, 2);

      await tester.tap(numberButton(1));
      await tester.pump(GameConstants.wiggleDuration);
      await tester.tap(numberButton(2));
      await tester.pump(GameConstants.wiggleDuration);

      final progress = container.read(gameStateProvider).progress;
      expect((progress.band, progress.level), (2, 1));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(StorageService.progressKey),
        contains('"level":1'),
      );
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('three correct answers level up with a bigger celebration', (
      tester,
    ) async {
      final audio = MockAudioService();
      final container = await pumpWithProviders(
        tester,
        const ToyBasketView(),
        problems: const [threeBones],
        audio: audio,
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(numberButton(3));
        await tester.pump();
        if (i < 2) await tester.pump(GameConstants.autoAdvanceDelay);
      }

      final state = container.read(gameStateProvider);
      expect(state.leveledUp, isTrue);
      expect((state.progress.band, state.progress.level), (1, 2));
      expect(audio.played.last, SoundCue.levelUp);
      expect(
        tester.widget<FeedbackOverlay>(find.byType(FeedbackOverlay)).levelUp,
        isTrue,
      );
      await tester.pump(GameConstants.autoAdvanceDelay);
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
