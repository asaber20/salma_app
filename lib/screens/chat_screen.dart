import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../widgets/chat_physical_inventory_report.dart';

const List<String> preferredBranchOrder = [
  'Riyadh',
  'Dammam',
  'Jeddah',
  'Khamis Mushit',
  'Khamis Mushait',
];

const List<String> preferredSegmentOrder = [
  'Human Pharma',
  'Pharma',
  'Animal Health',
  'Animal health',
  'Health Tech',
  'Health tech',
];

int sortWithPreferredOrder(String a, String b, List<String> preferredOrder) {
  int idxA = preferredOrder.indexWhere((p) => p.toLowerCase() == a.toLowerCase());
  int idxB = preferredOrder.indexWhere((p) => p.toLowerCase() == b.toLowerCase());

  if (idxA != -1 && idxB != -1) {
    return idxA.compareTo(idxB);
  } else if (idxA != -1) {
    return -1;
  } else if (idxB != -1) {
    return 1;
  } else {
    return a.compareTo(b);
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('chat_history');
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
    await prefs.setString('chat_history', messagesJson);
  }

  Future<void> _clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() {
      _messages.clear();
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

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

    String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';
    try {
      final response = await http.get(
        Uri.parse(
          'https://n8n.srv1348343.hstgr.cloud/webhook/physical_inventory',
        ).replace(queryParameters: {'imessage': text}),
        headers: {'authorization': bearerToken},
      );

      if (response.statusCode == 200) {
        // Update user message status to sent
        if (mounted) {
          setState(() {
            userMessage.status = MessageStatus.sent;
          });
        }

        try {
          final data = jsonDecode(response.body);

          List<String> replies = [];
          if (data is List) {
            bool isPhysicalInventory = data.isNotEmpty &&
                data.first is Map &&
                (data.first as Map).containsKey('BRANCH');

            if (isPhysicalInventory) {
              List<Map<String, dynamic>> parsedItems = [];
              Set<String> branchSet = {};
              Set<String> segmentSet = {};
              Set<String> stSet = {};
              Set<String> dateSet = {};

              int idx = 1;
              for (var item in data) {
                if (item is Map) {
                  String branch =
                      item['BRANCH']?.toString().trim() ?? 'Unknown Branch';
                  String segment =
                      item['SEGMENT']?.toString().trim() ?? 'General';
                  int bins =
                      int.tryParse(item['BINS']?.toString() ?? '0') ?? 0;
                  int countBins =
                      int.tryParse(item['COUNT_BINS']?.toString() ?? '0') ??
                          0;

                  String upDate = item['UP_DATE']?.toString().trim() ?? '';
                  String upTime = item['UP_TIME']?.toString().trim() ?? '';

                  String normDate = upDate.isEmpty
                      ? DateTime.now().toIso8601String().split('T').first
                      : upDate;

                  String hourLabel = '08:00';
                  if (upTime.contains(':')) {
                    final tParts = upTime.split(':');
                    if (tParts.isNotEmpty) {
                      hourLabel = "${tParts[0].padLeft(2, '0')}:00";
                    }
                  } else {
                    // Spread sample items across standard working hours if UP_TIME is empty
                    int hourInt = 8 + (idx % 9);
                    hourLabel = "${hourInt.toString().padLeft(2, '0')}:00";
                  }

                  String rawSt = item['ST']?.toString().trim() ?? 'Ambient';
                  String st = (rawSt.toLowerCase() == 'dry' || rawSt.isEmpty)
                      ? 'Ambient'
                      : rawSt;

                  branchSet.add(branch);
                  segmentSet.add(segment);
                  stSet.add(st);
                  dateSet.add(normDate);

                  parsedItems.add({
                    'branch': branch,
                    'segment': segment,
                    'st': st,
                    'bins': bins,
                    'countBins': countBins,
                    'date': normDate,
                    'time': hourLabel,
                  });
                  idx++;
                }
              }

              final sortedBranches = branchSet.toList()
                ..sort((a, b) => sortWithPreferredOrder(a, b, preferredBranchOrder));

              final sortedSegments = segmentSet.toList()
                ..sort((a, b) => sortWithPreferredOrder(a, b, preferredSegmentOrder));

              const List<String> preferredStOrder = ['Ambient', 'Cold'];
              final sortedStList = stSet.toList()
                ..sort((a, b) => sortWithPreferredOrder(a, b, preferredStOrder));

              final now = DateTime.now();

              final dashboardMessage = ChatMessage(
                text: "Physical Inventory Report",
                isUser: false,
                timestamp: now,
                type: ChatMessageType.physicalDashboard,
                chartData: {
                  'rawItems': parsedItems,
                  'branches': sortedBranches,
                  'segments': sortedSegments,
                  'stList': sortedStList,
                  'dates': dateSet.toList()..sort(),
                },
              );

              if (mounted) {
                setState(() {
                  _messages.insert(0, dashboardMessage);
                });
                _saveMessages();
              }
            } else {
              for (var item in data) {
                if (item is Map) {
                  if (item.containsKey('Line')) {
                    replies.add(item['Line'].toString());
                  } else if (item.containsKey('line')) {
                    replies.add(item['line'].toString());
                  } else if (item.containsKey('text')) {
                    replies.add(item['text'].toString());
                  } else if (item.containsKey('output')) {
                    replies.add(item['output'].toString());
                  } else {
                    replies.add(
                        item.toString().replaceAll(RegExp(r'[{}]'), ''));
                  }
                } else if (item is String) {
                  replies.add(item);
                } else {
                  replies.add(item.toString());
                }
              }
            }
          } else {
            String rawText = "";
            if (data is Map) {
              if (data.containsKey('text')) {
                rawText = data['text'].toString();
              } else if (data.containsKey('output')) {
                rawText = data['output'].toString();
              } else {
                // If it's a map but no known key, convert to string and remove braces
                rawText = data.toString().replaceAll(RegExp(r'[{}]'), '');
              }
            } else {
              // Raw body fallback, also removing braces just in case
              rawText = response.body.replaceAll(RegExp(r'[{}]'), '');
            }

            // Split by newlines if it's a single text block
            if (rawText.isNotEmpty) {
              replies.addAll(
                rawText.split('\n').where((line) => line.trim().isNotEmpty),
              );
            }
          }

          if (mounted && replies.isNotEmpty) {
            setState(() {
              for (var reply in replies) {
                _messages.insert(
                  0,
                  ChatMessage(
                    text: reply
                        .replaceAll('"', '')
                        .trim(), // Clean up quotes if any
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              }
            });
            _saveMessages();
          }
        } catch (e) {
          // If parsing fails (e.g. raw text), just show raw body
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
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${response.statusCode} - ${response.reasonPhrase}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: const AssetImage(
                'assets/images/Salma_image.jpeg',
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
                  'AI Digital Assistant',
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
              color: const Color(0xFFE5DDD5), // WhatsApp-like background color
              child: ListView.builder(
                controller: _scrollController,
                reverse: true, // Start from bottom
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
              child: const Text(
                "Salma is typing...",
                style: TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.transparent, // Parent background
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 6.0),
                  LiquidRefreshButton(
                    isLoading: _isTyping,
                    onPressed: () => _handleSubmitted(
                        "Last update for the Annual Physical Inventory"),
                  ),
                  const SizedBox(width: 4.0),
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
                            vertical: 10.0, horizontal: 8.0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.mic_none_outlined,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => _showVoiceOverlay(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF303489),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoiceOverlay(BuildContext context) {
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
                      'assets/images/Salma_image.jpeg',
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
}

class LiquidRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const LiquidRefreshButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<LiquidRefreshButton> createState() => _LiquidRefreshButtonState();
}

class _LiquidRefreshButtonState extends State<LiquidRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(covariant LiquidRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isLoading && _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _rotationController.forward(from: 0.0);
          widget.onPressed();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF3CCEFF).withValues(alpha: 0.3),
        highlightColor: const Color(0xFF8045DD).withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF303489), // Deep Navy
                Color(0xFF8045DD), // Purple
                Color(0xFF2659E4), // Royal Blue
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8045DD).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _rotationController,
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                "Sync",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
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
