import 'package:bluey_number_adventures/core/constants/game_constants.dart';
import 'package:bluey_number_adventures/presentation/views/home_view.dart';
import 'package:bluey_number_adventures/presentation/views/toy_basket_view.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('home has one large PLAY button that opens the toy basket', (
    tester,
  ) async {
    await pumpWithProviders(tester, const HomeView());

    final size = tester.getSize(find.byKey(HomeView.playButtonKey));
    expect(size.width, greaterThanOrEqualTo(GameConstants.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(GameConstants.minTouchTarget));

    await tester.tap(find.byKey(HomeView.playButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ToyBasketView), findsOneWidget);

    // The home button returns to the splash screen.
    await tester.tap(find.byKey(ToyBasketView.homeButtonKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ToyBasketView), findsNothing);
  });
}
