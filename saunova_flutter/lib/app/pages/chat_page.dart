import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saunova/app/theme/app_colors.dart';
import '../../log/app_logger.dart';
import '../services/api_service.dart';

// Message Model
class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });
}

// Main Chat Screen
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = false;
  String? _sessionId;

  StreamSubscription? _streamSubscription;

  String? _currentAssistantId;

  late AnimationController _headerController;
  late AnimationController _pulseController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );

    _headerController.forward();
    _initializeChat();
    _getUserId();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _streamSubscription?.cancel();
    _headerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _sessionId = 'user_${user.uid}';
      });
    }
  }

  void _initializeChat() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        role: 'assistant',
        content: 'Hello! I\'m your sauna assistant. How can I help you today?',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _loadChatHistory(List<dynamic> history) {
    final historyMessages = history
        .where((msg) => msg['role'] == 'human' || msg['role'] == 'ai')
        .map(
          (msg) => ChatMessage(
            id: 'history-${msg.hashCode}',
            role: msg['role'] == 'ai' ? 'assistant' : 'human',
            content: msg['content'],
            timestamp: DateTime.now(),
          ),
        )
        .toList();

    if (historyMessages.length > _messages.length + 2) {
      setState(() {
        _messages.clear();
        _messages.addAll(historyMessages);
      });
    }
  }

  void _updateAssistantMessage(
    String id,
    String content, {
    bool isError = false,
  }) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: id,
          role: 'assistant',
          content: content,
          timestamp: _messages[index].timestamp,
          isError: isError,
        );
      }
    });
    _scrollToBottom();
  }

  void _updateAssistantMessageSources(String id, List<String> sources) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: id,
          role: _messages[index].role,
          content: _messages[index].content,
          timestamp: _messages[index].timestamp,
        );
      }
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    if (_inputController.text.trim().isEmpty || _loading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'human',
      content: _inputController.text.trim(),
      timestamp: DateTime.now(),
    );

    _addMessage(userMessage);
    final messageText = _inputController.text.trim();
    _inputController.clear();

    final assistantId =
        'assistant-${DateTime.now().millisecondsSinceEpoch + 1}';
    _currentAssistantId = assistantId;

    final assistantMessage = ChatMessage(
      id: assistantId,
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
    );

    _addMessage(assistantMessage);
    setState(() {
      _loading = true;
    });

    await _sendMessageViaHttp(messageText);
  }

  Future<void> _sendMessageViaHttp(String message) async {
    try {
      final response = await ApiService.askQuestion(message);
      AppLogger.info('Received HTTP response: $response');

      if (response['session_id'] != null && _sessionId == null) {
        setState(() {
          _sessionId = response['session_id'];
        });
      }

      if (_currentAssistantId != null) {
        _updateAssistantMessage(
          _currentAssistantId!,
          response['answer'] ?? "Sorry, I couldn't process that.",
        );

        if (response['sources'] != null) {
          _updateAssistantMessageSources(
            _currentAssistantId!,
            List<String>.from(response['sources']),
          );
        }
      }

      if (response['chat_history'] != null) {
        _loadChatHistory(response['chat_history']);
      }
    } catch (e) {
      AppLogger.error('Error via HTTP: $e');
      if (_currentAssistantId != null) {
        _updateAssistantMessage(
          _currentAssistantId!,
          'Sorry, an error occurred. Please try again.',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
      _currentAssistantId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.primaryColor.withOpacityValue(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(theme),
              Expanded(
                child: Stack(
                  children: [
                    // Messages List
                    _messages.isEmpty && !_loading
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 20.0,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _messages.length + (_loading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length) {
                                return _ModernTypingIndicator(
                                  animation: _pulseController,
                                );
                              }
                              final message = _messages[index];
                              return _ModernChatBubble(
                                message: message,
                                index: index,
                              );
                            },
                          ),
                  ],
                ),
              ),
              _buildModernInputField(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacityValue(0.8),
                ],
              ),
            ),
          ),
          // Animated Waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ChatWavePainter(_headerAnimation.value),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // AI Icon with pulse
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacityValue(0.2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacityValue(
                              0.1 + (_pulseController.value * 0.2),
                            ),
                            blurRadius: 8 + (_pulseController.value * 8),
                            spreadRadius: _pulseController.value * 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: Text(
                          'Sauna Assistant',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacityValue(
                                      0.5,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Online & Ready',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacityValue(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu button
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    _showChatMenu(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withOpacityValue(0.1),
                    theme.primaryColor.withOpacityValue(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacityValue(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about saunas!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityValue(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacityValue(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.primaryColor.withOpacityValue(0.1),
                  ),
                ),
                child: TextField(
                  controller: _inputController,
                  enabled: !_loading,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTapDown: (_) {
                // Add haptic feedback if desired
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _loading
                        ? [
                            theme.primaryColor.withOpacityValue(0.5),
                            theme.primaryColor.withOpacityValue(0.3),
                          ]
                        : [
                            theme.primaryColor,
                            theme.primaryColor.withOpacityValue(0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _loading
                      ? []
                      : [
                          BoxShadow(
                            color: theme.primaryColor.withOpacityValue(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _loading ? null : _handleSendMessage,
                    child: Center(
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _MenuOption(
              icon: Icons.delete_outline,
              label: 'Clear Chat',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _initializeChat();
                });
              },
            ),
            _MenuOption(
              icon: Icons.info_outline,
              label: 'About Assistant',
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernChatBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;

  const _ModernChatBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'human';

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacityValue(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withOpacityValue(0.8),
                          ],
                        )
                      : null,
                  color: isUser
                      ? null
                      : message.isError
                      ? Colors.red.withOpacityValue(0.1)
                      : theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  border: !isUser
                      ? Border.all(
                          color: message.isError
                              ? Colors.red.withOpacityValue(0.3)
                              : theme.dividerColor.withOpacityValue(0.1),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? theme.primaryColor.withOpacityValue(0.2)
                          : Colors.black.withOpacityValue(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? Colors.white
                            : message.isError
                            ? Colors.red
                            : null,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUser
                            ? Colors.white.withOpacityValue(0.7)
                            : theme.textTheme.bodySmall?.color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ModernTypingIndicator extends StatelessWidget {
  final AnimationController animation;

  const _ModernTypingIndicator({required this.animation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacityValue(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: theme.dividerColor.withOpacityValue(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (animation.value + delay) % 1.0;
                    final scale = 0.6 + (math.sin(value * 2 * math.pi) * 0.4);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacityValue(
                          0.6 + (scale * 0.4),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: theme.primaryColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatWavePainter extends CustomPainter {
  final double animationValue;

  _ChatWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacityValue(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();

    for (int i = 0; i < 2; i++) {
      final waveHeight = 15.0 + (i * 8);
      final offset = animationValue * 100 * (i + 1);

      path.reset();
      path.moveTo(0, size.height * 0.6 + (i * 15));

      for (double x = 0; x <= size.width; x++) {
        final y =
            size.height * 0.6 +
            (i * 15) +
            math.sin((x / size.width * 4 * math.pi) + offset) * waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.color = Colors.white.withOpacityValue(0.06 + (i * 0.02));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ChatWavePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
