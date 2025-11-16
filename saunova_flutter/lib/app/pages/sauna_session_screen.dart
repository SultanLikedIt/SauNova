import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saunova/app/core/core.dart';
import 'package:saunova/app/models/session.dart';
import 'package:saunova/app/pages/session_detail_page.dart';
import 'package:saunova/app/services/api_service.dart';
import 'package:saunova/app/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:saunova/app/theme/app_colors.dart';
import 'package:saunova/log/app_logger.dart';

const int _kMinSessionDurationInSeconds = 10; // 5 minutes
const int _kMaxSessionDurationInSeconds = 3600; // 1 hours

class SaunaSessionScreen extends ConsumerStatefulWidget {
  const SaunaSessionScreen({super.key});

  @override
  ConsumerState<SaunaSessionScreen> createState() => _SaunaSessionScreenState();
}

class _SaunaSessionScreenState extends ConsumerState<SaunaSessionScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  bool _isActive = false;
  int _durationInSeconds = 0;
  int _temperature = 80;
  int _humidity = 10;
  late TextEditingController _sessionLengthController;
  Timer? _timer;

  bool _loadingRecommendations = false;
  // TODO: Replace with actual data from backend
  final Map<String, dynamic> _recommendations = {};
  List<Session> _sessionHistory = [];

  // Animation controller for timer pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _sessionLengthController = TextEditingController(text: '20');
    _setupAnimations();
    _resumeActiveSessionIfExists();
    // _fetchRecommendations(); // Optionally fetch on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startPulseAnimation() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionLengthController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Checks for an active session on storage and resumes it if found.
  void _resumeActiveSessionIfExists() {
    final startTime = StorageService.activeSessionStartTime;
    if (startTime == null) return;

    final elapsed = DateTime.now().difference(startTime).inSeconds;

    if (elapsed >= _kMaxSessionDurationInSeconds) {
      StorageService.setActiveSessionStartTime(null);
    } else {
      setState(() {
        _isActive = true;
        _durationInSeconds = elapsed;
      });
      _startPulseAnimation();
      _startTimer();
    }
  }

  /// Starts a periodic timer that updates the duration every second.
  void _startTimer() async {
    await ApiService.startSession(
      _temperature.round(),
      _humidity.round(),
      int.parse(_sessionLengthController.text) * 60,
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_durationInSeconds >= _kMaxSessionDurationInSeconds) {
        _stopSession();
      } else {
        setState(() => _durationInSeconds++);
      }
    });
  }

  /// Starts a new sauna session.
  void _startSession() {
    // Hide keyboard if it's open
    FocusScope.of(context).unfocus();

    final double? targetDuration = double.tryParse(
      _sessionLengthController.text,
    );
    if (targetDuration == null || targetDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target duration.')),
      );
      return;
    }

    StorageService.setActiveSessionStartTime(DateTime.now());
    setState(() {
      _isActive = true;
      _durationInSeconds = 0;
    });
    _startPulseAnimation();
    _startTimer();
  }

  /// Handles the logic for stopping a session.
  void _stopSession() async {
    _timer?.cancel();
    final startTime = StorageService.activeSessionStartTime;

    if (_durationInSeconds < _kMinSessionDurationInSeconds ||
        startTime == null) {
      _cancelSession();
      return;
    }

    await ApiService.stopSession();
    _saveSession(startTime);
  }

  /// Saves the completed session data.
  void _saveSession(DateTime startTime) async {
    StorageService.setActiveSessionStartTime(null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved successfully!')),
      );
      setState(() {
        _isActive = false;
        _durationInSeconds = 0;
      });
      _stopPulseAnimation();
    }
  }

  /// Cancels the session without saving.
  void _cancelSession() {
    StorageService.setActiveSessionStartTime(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session canceled (less than 5 minutes).'),
        ),
      );
      setState(() {
        _isActive = false;
        _durationInSeconds = 0;
      });
      _stopPulseAnimation();
    }
  }

  // --- Placeholder and Utility Methods ---

  void _useRecommendations() {
    setState(() {
      _temperature = _recommendations['temperature'] ?? _temperature;
      _humidity = _recommendations['humidity'] ?? _humidity;
      _sessionLengthController.text =
          _recommendations['session_length']?.toStringAsFixed(0) ??
          _sessionLengthController.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recommended settings applied!')),
    );
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _loadingRecommendations = true);
    final data = await ApiService.getSaunaRecommendations();
    if (data != null) {
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
          _recommendations['temperature'] = (data['temperature']).round();
          _recommendations['humidity'] = (data['humidity']).round();
          _recommendations['session_length'] = (data['session_length']).round();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch recommendations.')),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    _sessionHistory = ref.watch(
      coreProvider.select((c) => c.userData!.getLatestSessions(5)),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(coreProvider.notifier).reload();
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTimerCard(),
                const SizedBox(height: 16),
                if (!_isActive) ...[
                  _buildRecommendationsCard(),
                  const SizedBox(height: 16),
                ],
                _buildSettingsCard(),
                const SizedBox(height: 16),
                _buildHistoryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Builder Methods ---

  Widget _buildTimerCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonText = _isActive ? 'End Session' : 'Start Session';
    final buttonColor = _isActive ? colorScheme.error : colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isActive
              ? [
                  colorScheme.primary.withOpacityValue(0.15),
                  colorScheme.primary.withOpacityValue(0.05),
                ]
              : [colorScheme.surface, colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isActive
              ? colorScheme.primary.withOpacityValue(0.3)
              : colorScheme.outlineVariant.withOpacityValue(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isActive
                ? colorScheme.primary.withOpacityValue(0.3)
                : colorScheme.shadow.withOpacityValue(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: _isActive ? 2 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated background glow when active
          if (_isActive)
            Positioned.fill(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        colorScheme.primary.withOpacityValue(0.1),
                        colorScheme.primary.withOpacityValue(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              children: [
                // Timer display
                ScaleTransition(
                  scale: _isActive
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
                          color: colorScheme.primary.withOpacityValue(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatDuration(_durationInSeconds),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 64,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Duration',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                if (_isActive && _sessionLengthController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacityValue(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Target: ${_sessionLengthController.text} min',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [buttonColor, buttonColor.withOpacityValue(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withOpacityValue(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isActive ? _stopSession : _startSession,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isActive) ...[
                              Icon(
                                Icons.stop_circle_outlined,
                                color: colorScheme.onError,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              Icon(
                                Icons.play_circle_outline,
                                color: colorScheme.onPrimary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              buttonText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isActive
                                    ? colorScheme.onError
                                    : colorScheme.onPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasRecommendations =
        _recommendations.isNotEmpty && !_loadingRecommendations;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary.withOpacityValue(0.15),
            colorScheme.secondary.withOpacityValue(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withOpacityValue(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacityValue(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondary.withOpacityValue(0.3),
                              colorScheme.secondary.withOpacityValue(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: colorScheme.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Recommendations',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loadingRecommendations)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  IconButton(
                    onPressed: _fetchRecommendations,
                    icon: Icon(Icons.refresh, color: colorScheme.secondary),
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            if (hasRecommendations) ...[
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 350) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildRecommendationDisplayItem(
                            icon: Icons.thermostat,
                            label: 'Temperature',
                            value: '${_recommendations['temperature']}°C',
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRecommendationDisplayItem(
                            icon: Icons.water_drop,
                            label: 'Humidity',
                            value: '${_recommendations['humidity']}%',
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildRecommendationDisplayItem(
                          icon: Icons.thermostat,
                          label: 'Temperature',
                          value: '${_recommendations['temperature']}°C',
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendationDisplayItem(
                          icon: Icons.water_drop,
                          label: 'Humidity',
                          value: '${_recommendations['humidity']}%',
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildRecommendationDisplayItem(
                icon: Icons.timer,
                label: 'Duration',
                value: '${_recommendations['session_length']} min',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondary,
                      colorScheme.secondary.withOpacityValue(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withOpacityValue(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _useRecommendations,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: colorScheme.onSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Apply Recommendations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (!_loadingRecommendations) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacityValue(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap refresh to get AI recommendations',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationDisplayItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacityValue(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacityValue(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacityValue(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacityValue(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Session Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Temperature
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacityValue(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 0),
                            Expanded(
                              child: Text(
                                'Temperature',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_temperature.round()}°C',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _temperature.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.primary.withOpacityValue(0.3),
                    onChanged: _isActive
                        ? null
                        : (value) =>
                              setState(() => _temperature = value.toInt()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Humidity
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacityValue(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Humidity',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondary,
                              colorScheme.secondary.withOpacityValue(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_humidity.round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _humidity.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 25,
                    activeColor: colorScheme.secondary,
                    inactiveColor: colorScheme.secondary.withOpacityValue(0.3),
                    onChanged: _isActive
                        ? null
                        : (value) => setState(() => _humidity = value.toInt()),
                  ),
                ],
              ),
            ),
            if (!_isActive) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacityValue(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: colorScheme.tertiary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _sessionLengthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        enabled: !_isActive,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.tertiary,
                        ),
                        decoration: InputDecoration(
                          hintText: '20',
                          filled: true,
                          fillColor: colorScheme.tertiary.withOpacityValue(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.tertiary.withOpacityValue(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.tertiary.withOpacityValue(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.tertiary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formatHistoryDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return minutes > 0 ? '${minutes}m' : '${secs}s';
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacityValue(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacityValue(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacityValue(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Session History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_sessionHistory.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacityValue(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacityValue(
                          0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No session history yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sessionHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = _sessionHistory[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SessionDetailPage(session: session),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary.withOpacityValue(0.05),
                              colorScheme.primary.withOpacityValue(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withOpacityValue(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacityValue(
                                  0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.local_fire_department,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMM d, HH:mm',
                                    ).format(session.startedAt),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.thermostat,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${session.temperatureC}°C',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.water_drop,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${session.humidityPercent}%',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
                              ),
                              child: Text(
                                formatHistoryDuration(session.durationSeconds),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
