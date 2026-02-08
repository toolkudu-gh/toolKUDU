import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/router.dart';
import 'shared/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs instead of hash-based (required for OAuth callbacks)
  usePathUrlStrategy();

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
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final isRedirecting = ref.watch(
              authStateProvider.select((s) => s.isOAuthRedirecting),
            );
            if (!isRedirecting) return child!;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Stack(
              children: [
                child!,
                Positioned.fill(
                  child: Material(
                    color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Redirecting to Google...',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
