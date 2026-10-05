import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/game_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/game_state_provider.dart';
import '../widgets/character_avatar.dart';
import 'toy_basket_view.dart';

/// Splash home: one big PLAY button, no reading required.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const playButtonKey = ValueKey('home-play-button');

  void _play(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ToyBasketView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.heelerBlue, AppColors.sandyYellowLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(GameConstants.spacing * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CharacterAvatar(
                        character: PupCharacter.bluey,
                        mood: CharacterMood.happy,
                        size: 110,
                      ),
                      SizedBox(width: GameConstants.spacing),
                      CharacterAvatar(
                        character: PupCharacter.bingo,
                        mood: CharacterMood.happy,
                        size: 110,
                      ),
                    ],
                  ),
                  const SizedBox(height: GameConstants.spacing),
                  SvgPicture.asset(
                    'assets/images/toy_basket.svg',
                    width: 180,
                    semanticsLabel: 'Toy basket',
                  ),
                  const SizedBox(height: GameConstants.spacing * 2),
                  _PlayButton(onPressed: () => _play(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
          button: true,
          label: 'Play',
          child: SizedBox.square(
            key: HomeView.playButtonKey,
            dimension: GameConstants.playButtonSize,
            child: Material(
              color: AppColors.bingoOrange,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.ink, width: 6),
              ),
              elevation: 10,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                splashColor: AppColors.sandyYellow,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: GameConstants.playButtonSize * 0.7,
                  color: AppColors.white,
                  shadows: [Shadow(color: AppColors.ink, offset: Offset(3, 3))],
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1,
          end: 1.06,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}
