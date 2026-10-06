import 'package:expensetracker/core/router/app_router.dart';
import 'package:expensetracker/views/app_shell/app_shell_drawer_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('drawer pages return to the previously opened shell state', (
    tester,
  ) async {
    const destinations = [
      (AppRoutes.profile, 'Profile'),
      (AppRoutes.categories, 'Categories'),
      (AppRoutes.notes, 'Notes'),
      (AppRoutes.settings, 'Settings'),
      (AppRoutes.privacyPolicy, 'Privacy Policy'),
    ];

    final router = GoRouter(
      initialLocation: AppRoutes.shell,
      routes: [
        ShellRoute(
          builder: (_, state, child) => Stack(
            fit: StackFit.expand,
            children: [
              _ShellPage(key: const ValueKey('shell')),
              IgnorePointer(
                ignoring: state.uri.path == AppRoutes.shell,
                child: child,
              ),
            ],
          ),
          routes: [
            GoRoute(
              path: AppRoutes.shell,
              builder: (_, _) => const SizedBox.expand(),
            ),
            for (final destination in destinations)
              GoRoute(
                path: destination.$1,
                builder: (_, _) => _DestinationPage(title: destination.$2),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Shell state: 1'), findsOneWidget);

    for (final destination in destinations) {
      await tester.tap(find.text(destination.$2).last);
      await tester.pumpAndSettle();
      expect(find.text(destination.$2), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Shell state: 1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }
  });
}

class _ShellPage extends StatefulWidget {
  const _ShellPage({super.key});

  @override
  State<_ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<_ShellPage> {
  var _state = 1;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text('Shell'),
    ),
    drawer: const Drawer(child: AppShellDrawerPages()),
    body: Center(child: Text('Shell state: $_state')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => setState(() => _state++),
      child: const Icon(Icons.add),
    ),
  );
}

class _DestinationPage extends StatelessWidget {
  const _DestinationPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Text(title),
    ),
  );
}
