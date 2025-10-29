import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PageEditorView extends StatelessWidget {
  const PageEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.s16),
          Text(
            'Workspace > Parent Page > This Page',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            'Page Title',
            style: textTheme.headlineLarge,
          ),
          const SizedBox(height: AppTokens.s16),
          _blockPlaceholder(context),
          const SizedBox(height: AppTokens.s8),
          _blockPlaceholder(context),
          const SizedBox(height: AppTokens.s8),
          _blockPlaceholder(context),
          const SizedBox(height: AppTokens.s24),
        ],
      ),
    );
  }

  Widget _blockPlaceholder(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.r6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
    );
  }
}
