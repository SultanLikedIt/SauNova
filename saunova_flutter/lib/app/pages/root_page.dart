import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saunova/app/pages/chat_page.dart';
import 'package:saunova/app/pages/dashboard_page.dart';
import 'package:saunova/app/pages/sauna_session_screen.dart';
import 'package:saunova/app/pages/social_page.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      child: PersistentTabView(
        tabs: [
          PersistentTabConfig(
            screen: DashboardScreen(),
            item: ItemConfig(
              icon: Icon(Icons.home),
              title: "Home",
              activeForegroundColor: theme.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: SaunaSessionScreen(),
            item: ItemConfig(
              icon: Icon(Icons.local_fire_department_rounded),
              title: "Session",
              activeForegroundColor: theme.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: SocialPage(),
            item: ItemConfig(
              icon: Icon(Icons.people_outline),
              title: "Social",
              activeForegroundColor: theme.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: ChatScreen(),
            item: ItemConfig(
              icon: Icon(Icons.chat_bubble_outline_outlined),
              title: "Settings",
              activeForegroundColor: theme.primaryColor,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style10BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: NavBarDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }
}
