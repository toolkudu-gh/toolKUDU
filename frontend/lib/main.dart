import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'shared/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: ToolKuduApp(),
    ),
  );
}

class ToolKuduApp extends ConsumerWidget {
  const ToolKuduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'ToolKUDU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
