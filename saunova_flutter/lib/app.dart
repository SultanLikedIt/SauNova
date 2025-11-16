import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saunova/app/pages/loading_page.dart';
import 'package:saunova/app/pages/login_page.dart';
import 'package:saunova/app/pages/no_connection_page.dart';
import 'package:saunova/app/pages/onboarding_page.dart';
import 'package:saunova/app/pages/root_page.dart';
import 'package:saunova/app/theme/app_theme.dart';
import 'package:saunova/app/theme/theme_provider.dart';

class Saunova extends ConsumerWidget {
  const Saunova({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saunova',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme,
      routes: {
        '/loading': (context) => LoadingPage(),
        '/root': (context) => RootPage(),
        '/login': (context) => LoginScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/no_connection': (context) => NoConnectionPage(),
      },
      initialRoute: '/loading',
    );
  }
}
