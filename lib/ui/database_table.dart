import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class DatabaseTableView extends StatelessWidget {
  const DatabaseTableView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Database: Tasks', style: textTheme.headlineMedium),
          const SizedBox(height: AppTokens.s16),
          Text('| Title | Status | Date | Tags | Person |', style: textTheme.bodyLarge),
          const SizedBox(height: AppTokens.s12),
          Text('Task A | In Progress | 02-10-2025 | tag1 | Alice', style: textTheme.bodyLarge),
          Text('Task B | Done | 01-10-2025 | tag2 | Bob', style: textTheme.bodyLarge),
          Text('Task C | Todo | 05-10-2025 | tag3 | Carol', style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
