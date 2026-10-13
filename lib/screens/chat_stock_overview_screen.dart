import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../widgets/chat_physical_inventory_report.dart';
import '../config/app_config.dart';

class ChatStockOverviewScreen extends StatefulWidget {
  final String employeeId;
  final bool triggerChatStart;

  const ChatStockOverviewScreen({
    super.key,
    this.employeeId = '',
    this.triggerChatStart = false,
  });

  @override
  State<ChatStockOverviewScreen> createState() => _ChatStockOverviewScreenState();
}

class _ChatStockOverviewScreenState extends State<ChatStockOverviewScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _typingText = "Salma is typing...";

  @override
  void initState() {
    super.initState();
    if (widget.triggerChatStart) {
      _clearMessages().then((_) {
        _fetchChatStart();
      });
    } else {
      _loadMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('chat_stock_history');
    if (messagesJson != null) {
      final List<dynamic> decodedIdx = jsonDecode(messagesJson);
      setState(() {
        _messages.clear();
        _messages.addAll(
          decodedIdx.map((e) => ChatMessage.fromJson(e)).toList(),
        );
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String messagesJson = jsonEncode(
      _messages.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('chat_stock_history', messagesJson);
  }

  Future<void> _clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_stock_history');
    setState(() {
      _messages.clear();
    });
  }

  Future<void> _fetchChatStart() async {
    setState(() {
      _isTyping = true;
      _typingText = "Salma is typing...";
    });

    String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';

    try {
      final response = await http.get(
        Uri.parse(AppConfig.stockOverviewEndpoint).replace(queryParameters: {
          'imessage': '[CHAT_START]',
          'employee_id': widget.employeeId,
        }),
        headers: {'authorization': bearerToken},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          List<String> replies = [];

          if (data is List) {
            for (var item in data) {
              if (item is Map) {
                if (item.containsKey('text')) {
                  replies.add(item['text'].toString());
                } else if (item.containsKey('output')) {
                  replies.add(item['output'].toString());
                } else {
                  replies.add(item.toString().replaceAll(RegExp(r'[{}]'), ''));
                }
              } else if (item is String) {
                replies.add(item);
              }
            }
          } else if (data is Map) {
            if (data.containsKey('text')) {
              replies.add(data['text'].toString());
            } else if (data.containsKey('output')) {
              replies.add(data['output'].toString());
            } else {
              replies.add(data.toString().replaceAll(RegExp(r'[{}]'), ''));
            }
          } else {
            replies.add(response.body.replaceAll(RegExp(r'[{}]'), ''));
          }

          if (replies.isEmpty) {
            replies.add("Hello! I am Salma, your Stock Overview Assistant. Tap the action button below to explore inventory levels, suppliers, and expiry analysis.");
          }

          if (mounted) {
            setState(() {
              for (var reply in replies) {
                _messages.insert(
                  0,
                  ChatMessage(
                    text: reply.replaceAll('"', '').trim(),
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              }
            });
            _saveMessages();
            _scrollToBottom();
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _messages.insert(
                0,
                ChatMessage(
                  text: response.body.replaceAll(RegExp(r'[{}]'), ''),
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
            });
            _saveMessages();
            _scrollToBottom();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _messages.insert(
              0,
              ChatMessage(
                text: "Hello! I am Salma, your Stock Overview Assistant. Tap the action button below to select a report.",
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          });
          _saveMessages();
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: "Hello! I am Salma, your Stock Overview Assistant. Tap the action button below to select a report.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _saveMessages();
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _typingText = "Salma is typing...";
        });
      }
    }
  }

  Future<void> _handleSubmitted(String text, {bool isReportAction = false}) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    final String apiMessage = isReportAction ? '[REPORT]' : text;

    if (!isReportAction) {
      final userMessage = ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );
      setState(() {
        _messages.insert(0, userMessage);
        _isTyping = true;
      });
      _saveMessages();
      _scrollToBottom();
    } else {
      setState(() {
        _isTyping = true;
        _typingText = "Salma is preparing the report for you";
      });
    }

    String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';

    try {
      final response = await http.get(
        Uri.parse(AppConfig.stockOverviewEndpoint).replace(queryParameters: {
          'imessage': apiMessage,
          'employee_id': widget.employeeId,
        }),
        headers: {'authorization': bearerToken},
      );

      if (response.statusCode == 200) {
        if (!isReportAction) {
          if (mounted) {
            setState(() {
              // message sent
            });
          }
        }

        try {
          final data = jsonDecode(response.body);

          if (data is List && data.isNotEmpty && data.first is Map &&
              ((data.first as Map).containsKey('plant') ||
                  (data.first as Map).containsKey('PLANT') ||
                  (data.first as Map).containsKey('stock_value'))) {
            
            final now = DateTime.now();
            final reportMessage = ChatMessage(
              text: text,
              isUser: false,
              timestamp: now,
              type: ChatMessageType.stockOverviewReport,
              chartData: {
                'rawItems': data,
              },
            );

            if (mounted) {
              setState(() {
                _messages.insert(0, reportMessage);
              });
              _saveMessages();
              _scrollToBottom();
            }
          } else {
            List<String> replies = [];

            if (data is List) {
              for (var item in data) {
                if (item is Map) {
                  if (item.containsKey('text')) {
                    replies.add(item['text'].toString());
                  } else if (item.containsKey('output')) {
                    replies.add(item['output'].toString());
                  } else {
                    replies.add(item.toString().replaceAll(RegExp(r'[{}]'), ''));
                  }
                } else if (item is String) {
                  replies.add(item);
                }
              }
            } else if (data is Map) {
              if (data.containsKey('text')) {
                replies.add(data['text'].toString());
              } else if (data.containsKey('output')) {
                replies.add(data['output'].toString());
              } else {
                replies.add(data.toString().replaceAll(RegExp(r'[{}]'), ''));
              }
            } else {
              replies.add(response.body.replaceAll(RegExp(r'[{}]'), ''));
            }

            if (mounted && replies.isNotEmpty) {
              setState(() {
                for (var reply in replies) {
                  _messages.insert(
                    0,
                    ChatMessage(
                      text: reply.replaceAll('"', '').trim(),
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                  );
                }
              });
              _saveMessages();
              _scrollToBottom();
            }
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _messages.insert(
                0,
                ChatMessage(
                  text: response.body.replaceAll(RegExp(r'[{}]'), ''),
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
            });
            _saveMessages();
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, color: Color(0xFF8045DD), size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Select a Stock Report",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF303489),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionChip("Stock overview", Icons.inventory_2_rounded, const Color(0xFF303489), true),
                  _buildActionChip("Insurance limits", Icons.security_rounded, const Color(0xFF8045DD), true),
                  _buildActionChip("Top Suppliers", Icons.local_shipping_rounded, const Color(0xFF2659E4), true),
                  _buildActionChip("Top Items", Icons.star_rounded, const Color(0xFF00BFA5), true),
                  _buildActionChip("Expiry Analysis", Icons.event_busy_rounded, const Color(0xFFE65100), true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionChip(String actionName, IconData icon, Color color, bool isAvailable) {
    return ActionChip(
      avatar: Icon(icon, color: isAvailable ? color : Colors.grey, size: 16),
      label: Text(
        isAvailable ? actionName : "$actionName (Soon)",
        style: TextStyle(
          color: isAvailable ? color : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: isAvailable ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        Navigator.pop(context);
        if (isAvailable) {
          _handleSubmitted(actionName, isReportAction: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$actionName report is coming soon!"),
              backgroundColor: const Color(0xFF303489),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                _showAvatarImageViewer(
                  context,
                  'assets/images/salma_stock_overview_avatar.jpeg',
                  'Stock Overview Agent',
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: const AssetImage(
                  'assets/images/salma_stock_overview_avatar.jpeg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Salma',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Stock Overview Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearMessages,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFE5DDD5),
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
          ),
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              width: double.infinity,
              child: Text(
                _typingText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ],
              ),
              child: _buildTextComposer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 16.0),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFF33333D), size: 26),
            onPressed: _showActionMenu,
            tooltip: 'Stock Reports',
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 0.0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.mic_none_outlined,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                    onPressed: () => _showVoiceOverlay(context),
                  ),
                  const SizedBox(width: 4.0),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoiceOverlay(BuildContext context) {
    if (!AppConfig.enableVoiceRecognition) {
      _showUnderDevelopmentVoiceOverlay(context);
      return;
    }
  }

  void _showUnderDevelopmentVoiceOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white10,
                    backgroundImage: const AssetImage(
                      'assets/images/salma_stock_overview_avatar.jpeg',
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Voice commands will be available soon, please wait",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const VoiceWaveform(),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAvatarImageViewer(BuildContext context, String imagePath, String agentName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          agentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InteractiveViewer(
                    child: Hero(
                      tag: imagePath,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({super.key});

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 100),
          painter: VoiceWavePainter(_controller.value),
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final double animationValue;
  VoiceWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    // Siri-like waves (multiple overlapping sine waves)
    _drawWave(canvas, width, centerY, 0.4, 0.6, const Color(0xFF00BFA5), 0);
    _drawWave(canvas, width, centerY, 0.3, 0.4, const Color(0xFF00BCD4), 2);
    _drawWave(canvas, width, centerY, 0.5, 0.3, const Color(0xFF3F51B5), 4);
  }

  void _drawWave(
    Canvas canvas,
    double width,
    double centerY,
    double amplitudeFactor,
    double speedFactor,
    Color color,
    double phaseShift,
  ) {
    final path = Path();
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    path.moveTo(0, centerY);

    for (double x = 0; x <= width; x++) {
      double relativeX = x / width;
      // Envelope to taper the ends
      double envelope = 1.0 - (2.0 * relativeX - 1.0).abs();
      envelope = envelope * envelope; // Smoother taper

      double y =
          centerY +
          amplitudeFactor *
              30 *
              envelope *
              math.sin(
                2 * math.pi * 2 * relativeX +
                    2 * math.pi * animationValue * speedFactor +
                    phaseShift,
              );
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant VoiceWavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
