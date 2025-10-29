import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BoardView extends StatelessWidget {
  const BoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kanban: Group by Status', style: textTheme.headlineMedium),
          const SizedBox(height: AppTokens.s16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _column(context, 'Todo', 'Card 1', textTheme),
                const SizedBox(width: AppTokens.s16),
                _column(context, 'In Progress', 'Card 2', textTheme),
                const SizedBox(width: AppTokens.s16),
                _column(context, 'Done', 'Card 3', textTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(BuildContext context, String title, String cardTitle, TextTheme textTheme) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppTokens.r8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTokens.s12),
            _card(context, cardTitle, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, TextTheme textTheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.r6),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: textTheme.bodyLarge),
      ),
    );
  }
}
