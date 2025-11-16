import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saunova/app/pages/login_page.dart';
import 'package:saunova/app/theme/app_colors.dart';
import 'package:saunova/app/theme/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../core/core.dart';
import '../models/session.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flameController;
  late Animation<double> _flameAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await ref.read(coreProvider.notifier).updateImage(file);
    }
  }

  Future<void> deleteImage() async {
    await ref.read(coreProvider.notifier).deleteImage();
  }

  void _setupAnimation() {
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _flameAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userData = ref.watch(coreProvider).userData;

    if (userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your sauna data...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalSessions = userData.sessions.length;
    final totalMinutes = userData.sessions.fold<int>(
      0,
      (sum, session) => sum + (session.durationSeconds ~/ 60),
    );
    final currentStreak = _calculateCurrentStreak(userData.sessions);
    final longestStreak = _calculateLongestStreak(userData.sessions);
    final recentSessions = userData.sessions.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final displaySessions = recentSessions.take(5).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Dashboard',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: userData.image == null
                  ? Icon(Icons.person, color: colorScheme.onPrimary, size: 24)
                  : ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userData.image!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Streak Card
              _buildHeroStreakCard(currentStreak, theme, colorScheme),
              const SizedBox(height: 20),

              // Stats Grid
              _buildStatsGrid(
                totalSessions,
                totalMinutes,
                longestStreak,
                theme,
                colorScheme,
              ),
              const SizedBox(height: 20),

              // Recent Activity Section
              _buildRecentActivitySection(displaySessions, theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userData = ref.watch(coreProvider).userData;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primary,
                        child: userData?.image == null
                            ? Icon(
                                Icons.person,
                                color: colorScheme.onPrimary,
                                size: 40,
                              )
                            : ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: userData!.image!,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.image),
                                        title: const Text('Change Image'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          pickImage();
                                        },
                                      ),
                                      if (userData?.image != null)
                                        ListTile(
                                          leading: const Icon(Icons.delete),
                                          title: const Text('Delete Image'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            deleteImage();
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sauna Enthusiast',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerTile(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                    theme: theme,
                  ),
                  ExpansionTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: colorScheme.onSurface,
                    ),
                    title: const Text('Theme'),
                    children: [
                      _buildDrawerSubTile(
                        icon: Icons.light_mode_outlined,
                        title: 'Light',
                        onTap: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .setTheme(ThemeMode.light);
                        },
                        theme: theme,
                      ),
                      _buildDrawerSubTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark',
                        onTap: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .setTheme(ThemeMode.dark);
                        },
                        theme: theme,
                      ),
                      _buildDrawerSubTile(
                        icon: Icons.phone_android_outlined,
                        title: 'System',
                        onTap: () {
                          ref
                              .read(themeModeProvider.notifier)
                              .setTheme(ThemeMode.system);
                        },
                        theme: theme,
                      ),
                    ],
                  ),
                  _buildDrawerTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      // TODO: Implement profile navigation
                    },
                    theme: theme,
                  ),
                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      // TODO: Implement settings navigation
                    },
                    theme: theme,
                  ),
                  _buildDrawerTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      // TODO: Implement help navigation
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDrawerTile(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () {
                FirebaseAuth.instance.signOut();
                pushReplacementWithoutNavBar(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  result: (_) => false,
                );
              },
              theme: theme,
              isDestructive: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDrawerSubTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 72, right: 20),
    );
  }

  Widget _buildHeroStreakCard(
    int currentStreak,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final streakMessage = currentStreak > 0
        ? 'Keep the momentum'
        : 'Start your journey today';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacityValue(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacityValue(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withOpacityValue(0.1),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withOpacityValue(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Streak',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary.withOpacityValue(
                                0.9,
                              ),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$currentStreak',
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  fontSize: 48,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  bottom: 6,
                                ),
                                child: Text(
                                  currentStreak == 1 ? 'day' : 'days',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary
                                        .withOpacityValue(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ScaleTransition(
                      scale: _flameAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacityValue(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          size: 40,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacityValue(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentStreak > 0
                            ? Icons.emoji_events
                            : Icons.emoji_events_outlined,
                        color: colorScheme.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          streakMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    int totalSessions,
    int totalMinutes,
    int longestStreak,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today_outlined,
                label: 'Sessions',
                value: totalSessions.toString(),
                theme: theme,
                colorScheme: colorScheme,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time_outlined,
                label: 'Minutes',
                value: totalMinutes.toString(),
                theme: theme,
                colorScheme: colorScheme,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLongestStreakCard(longestStreak, theme, colorScheme),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, color.withOpacityValue(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacityValue(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacityValue(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacityValue(0.2),
                  color.withOpacityValue(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacityValue(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 28,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLongestStreakCard(
    int longestStreak,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacityValue(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacityValue(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withOpacityValue(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.military_tech_outlined,
              color: colorScheme.tertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Longest Streak',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$longestStreak ${longestStreak == 1 ? 'day' : 'days'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    List<Session> sessions,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'Recent Activity',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (sessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacityValue(0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.spa_outlined,
                  size: 56,
                  color: colorScheme.onSurfaceVariant.withOpacityValue(0.5),
                ),
                const SizedBox(height: 14),
                Text(
                  'No sessions yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start your first sauna session\nto see your activity here',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacityValue(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...sessions.map(
            (session) => _buildSessionCard(session, theme, colorScheme),
          ),
      ],
    );
  }

  Widget _buildSessionCard(
    Session session,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.primary.withOpacityValue(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacityValue(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacityValue(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacityValue(0.2),
                            colorScheme.primary.withOpacityValue(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacityValue(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatDate(session.startedAt),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacityValue(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacityValue(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatDuration(session.durationSeconds),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSessionDetail(
                  icon: Icons.thermostat_outlined,
                  label: '${session.temperatureC}°C',
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSessionDetail(
                  icon: Icons.water_drop_outlined,
                  label: '${session.humidityPercent}%',
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetail({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacityValue(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Functions ---

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date);
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds.remainder(60);
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }

  // Helper to get unique, sorted dates from sessions
  List<DateTime> _getUniqueSessionDays(List<Session> sessions) {
    if (sessions.isEmpty) return [];
    // Use a Set to get unique days, ignoring time
    final uniqueDays = sessions
        .map((s) => DateUtils.dateOnly(s.startedAt))
        .toSet()
        .toList();
    uniqueDays.sort((a, b) => a.compareTo(b));
    return uniqueDays;
  }

  int _calculateCurrentStreak(List<Session> sessions) {
    final uniqueDays = _getUniqueSessionDays(sessions);
    if (uniqueDays.isEmpty) return 0;

    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final lastSessionDay = uniqueDays.last;

    // Streak is only valid if the last session was today or yesterday
    if (lastSessionDay != today && lastSessionDay != yesterday) {
      return 0;
    }

    int streak = 0;
    for (int i = uniqueDays.length - 1; i >= 0; i--) {
      final day = uniqueDays[i];
      final expectedDay = today.subtract(Duration(days: streak));
      if (day == expectedDay) {
        streak++;
      } else {
        break; // Found a gap in the streak
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<Session> sessions) {
    final uniqueDays = _getUniqueSessionDays(sessions);
    if (uniqueDays.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;
    for (int i = 1; i < uniqueDays.length; i++) {
      final prevDate = uniqueDays[i - 1];
      final currDate = uniqueDays[i];

      // Check if the current session day is exactly one day after the previous
      if (currDate.difference(prevDate).inDays == 1) {
        currentStreak++;
      } else {
        // Reset streak if there's a gap
        currentStreak = 1;
      }

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }
    return longestStreak;
  }
}
