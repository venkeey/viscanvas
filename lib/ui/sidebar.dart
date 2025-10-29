// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../theme/tokens.dart';

// class Sidebar extends StatelessWidget {
//   final VoidCallback onNewPage;
//   const Sidebar({super.key, required this.onNewPage});

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//     return Container(
//       width: AppTokens.sidebarWidth,
//       color: Theme.of(context).colorScheme.surfaceVariant,
//       child: Column(
//         children: [
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.all(AppTokens.s16),
//               children: [
//                 _sectionTitle('Workspace ▼', textTheme),
//                 const SizedBox(height: AppTokens.s12),
//                 Divider(height: 1, color: Theme.of(context).dividerColor),
//                 const SizedBox(height: AppTokens.s16),
//                 _navGroup(context, '★ Favorites', [
//                   _NavItem(label: 'Starred Page A', path: '/page?id=starA'),
//                   _NavItem(label: 'Starred Page B', path: '/page?id=starB'),
//                 ], textTheme),
//                 const SizedBox(height: AppTokens.s16),
//                 _navGroup(context, '📄 My Pages', [
//                   _NavItem(label: 'Page 1', path: '/page?id=1'),
//                   _NavItem(label: 'Subpage 1.1', path: '/page?id=1.1', indent: true),
//                   _NavItem(label: 'Page 2', path: '/page?id=2'),
//                 ], textTheme),
//                 const SizedBox(height: AppTokens.s16),
//                 _navGroup(context, '📦 Templates', [
//                   _NavItem(label: 'Project Tracker', path: '/table?id=projects'),
//                   _NavItem(label: 'Notes', path: '/page?id=notes'),
//                 ], textTheme),
//                 const SizedBox(height: AppTokens.s16),
//                 InkWell(
//                   onTap: () => context.go('/page?trash=1'),
//                   child: _sectionTitle('🗑 Trash', textTheme),
//                 ),
//               ],
//             ),
//           ),
//           _newPageButton(context, textTheme),
//         ],
//       ),
//     );
//   }

//   Widget _sectionTitle(String text, TextTheme textTheme) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Text(
//         text,
//         style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
//       ),
//     );
//   }

//   Widget _navGroup(BuildContext context, String title, List<_NavItem> items, TextTheme textTheme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _sectionTitle(title, textTheme),
//         const SizedBox(height: AppTokens.s8),
//         ...items.map((item) => Padding(
//               padding: EdgeInsets.only(left: item.indent ? AppTokens.s16 : 0),
//               child: ListTile(
//                 dense: true,
//                 contentPadding: EdgeInsets.zero,
//                 title: Text(item.label, style: textTheme.bodyMedium),
//                 onTap: () => context.go(item.path),
//               ),
//             )),
//       ],
//     );
//   }

//   Widget _newPageButton(BuildContext context, TextTheme textTheme) {
//     return Container(
//       height: 40,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: TextButton(
//         onPressed: () => context.go('/page?new=1'),
//         child: Text('New Page', style: textTheme.bodyLarge),
//       ),
//     );
//   }
// }

// class _NavItem {
//   final String label;
//   final String path;
//   final bool indent;
//   _NavItem({required this.label, required this.path, this.indent = false});
// }
