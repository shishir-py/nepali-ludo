import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Floating reaction bubble shown near a player's area.
class ReactionBubble extends StatelessWidget {
  final String text;
  final bool isRight;

  const ReactionBubble({super.key, required this.text, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: NepaliColors.primary.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.3, end: 0)
        .then(delay: 2500.ms)
        .fadeOut(duration: 300.ms);
  }
}

/// Bottom sheet showing reaction options.
class ReactionPanel extends StatelessWidget {
  final void Function(String reaction) onReact;

  const ReactionPanel({super.key, required this.onReact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NepaliColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
              color: NepaliColors.gold.withValues(alpha: 0.4), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.react,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Emoji row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: S.defaultEmojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  onReact(emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NepaliColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'नेपाली प्रतिक्रियाहरू',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              itemCount: S.nepaliReactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final r = S.nepaliReactions[i];
                return GestureDetector(
                  onTap: () {
                    onReact(r);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: NepaliColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: NepaliColors.primary.withValues(alpha: 0.25)),
                    ),
                    child:
                        Text(r, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
