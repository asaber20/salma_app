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
];

const List<String> preferredSegmentOrder = [
  'Human Pharma',
  'Animal Health',
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

class ChatPhysicalInventoryScreen extends StatefulWidget {
  final String employeeId;
  final bool triggerChatStart;

  const ChatPhysicalInventoryScreen({
    super.key,
    this.employeeId = '',
    this.triggerChatStart = false,
  });

  @override
  State<ChatPhysicalInventoryScreen> createState() => _ChatPhysicalInventoryScreenState();
}

class _ChatPhysicalInventoryScreenState extends State<ChatPhysicalInventoryScreen> {
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

  Future<void> _fetchChatStart() async {
    setState(() {
      _isTyping = true;
      _typingText = "Salma is typing...";
    });

    String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';

    try {
      final response = await http.get(
        Uri.parse(
          'https://n8n.srv1348343.hstgr.cloud/webhook/physical_inventory',
        ).replace(queryParameters: {
          'imessage': '[CHAT_START]',
          'employee_id': widget.employeeId,
        }),
        headers: {'authorization': bearerToken},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          List<String> replies = [];
          bool renderedDashboard = false;

          if (data is List) {
            bool isPhysicalInventory = data.isNotEmpty &&
                data.first is Map &&
                ((data.first as Map).containsKey('BRANCH') ||
                    (data.first as Map).containsKey('branch') ||
                    (data.first as Map).containsKey('segment'));

            if (isPhysicalInventory) {
              List<Map<String, dynamic>> parsedItems = [];
              Set<String> branchSet = {};
              Set<String> segmentSet = {};
              Set<String> stSet = {};
              Set<String> dateSet = {};

              int idx = 1;
              for (var item in data) {
                if (item is Map) {
                  String branch = item['branch']?.toString().trim() ??
                      item['BRANCH']?.toString().trim() ??
                      'Unknown Branch';
                  String segment = item['segment']?.toString().trim() ??
                      item['SEGMENT']?.toString().trim() ??
                      'General';
                  int bins = int.tryParse(item['bins']?.toString() ??
                          item['BINS']?.toString() ??
                          '0') ??
                      0;
                  int countBins = int.tryParse(item['count_bins']?.toString() ??
                          item['COUNT_BINS']?.toString() ??
                          '0') ??
                      0;

                  String upDate = item['up_date']?.toString().trim() ??
                      item['UP_DATE']?.toString().trim() ??
                      '';
                  String upTime = item['up_time']?.toString().trim() ??
                      item['UP_TIME']?.toString().trim() ??
                      '';

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
                    int hourInt = 8 + (idx % 9);
                    hourLabel = "${hourInt.toString().padLeft(2, '0')}:00";
                  }

                  String rawSt = item['st']?.toString().trim() ??
                      item['ST']?.toString().trim() ??
                      'Dry';
                  String st = rawSt.isEmpty ? 'Dry' : rawSt;

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

              const List<String> preferredStOrder = ['Dry', 'Cold'];
              final sortedStList = stSet.toList()
                ..sort((a, b) => sortWithPreferredOrder(a, b, preferredStOrder));

              final now = DateTime.now();

              if (mounted) {
                setState(() {
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
                  _messages.insert(0, dashboardMessage);

                  // Insert AI Insight
                  final insightText = _generateAiInsight("Overall Progress", parsedItems, branchSet);
                  final insightMessage = ChatMessage(
                    text: insightText,
                    isUser: false,
                    timestamp: now.add(const Duration(milliseconds: 50)),
                    type: ChatMessageType.text,
                  );
                  _messages.insert(0, insightMessage);
                });
                renderedDashboard = true;
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
                    replies.add(item.toString().replaceAll(RegExp(r'[{}]'), ''));
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
                rawText = data.toString().replaceAll(RegExp(r'[{}]'), '');
              }
            } else {
              rawText = response.body.replaceAll(RegExp(r'[{}]'), '');
            }

            if (rawText.isNotEmpty) {
              replies.addAll(
                rawText.split('\n').where((line) => line.trim().isNotEmpty),
              );
            }
          }

          if (!renderedDashboard && mounted) {
            if (replies.isNotEmpty) {
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
            } else {
              setState(() {
                _messages.insert(
                  0,
                  ChatMessage(
                    text: response.body.isNotEmpty
                        ? response.body.replaceAll(RegExp(r'[{}]'), '').replaceAll('"', '').trim()
                        : "Hello! I am Salma, your Physical Inventory Assistant. How can I help you today?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            }
          }

          _saveMessages();
          _scrollToBottom();
        } catch (e) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load initial chat: $e')),
        );
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
    _scrollToBottom();

    String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';
    try {
      final response = await http.get(
        Uri.parse(
          'https://n8n.srv1348343.hstgr.cloud/webhook/physical_inventory',
        ).replace(queryParameters: {
          'imessage': text,
          'employee_id': widget.employeeId,
        }),
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
                ((data.first as Map).containsKey('BRANCH') ||
                    (data.first as Map).containsKey('branch') ||
                    (data.first as Map).containsKey('segment'));

            if (isPhysicalInventory) {
              List<Map<String, dynamic>> parsedItems = [];
              Set<String> branchSet = {};
              Set<String> segmentSet = {};
              Set<String> stSet = {};
              Set<String> dateSet = {};

              int idx = 1;
              for (var item in data) {
                if (item is Map) {
                  String branch = item['branch']?.toString().trim() ??
                      item['BRANCH']?.toString().trim() ??
                      'Unknown Branch';
                  String segment = item['segment']?.toString().trim() ??
                      item['SEGMENT']?.toString().trim() ??
                      'General';
                  int bins = int.tryParse(item['bins']?.toString() ??
                          item['BINS']?.toString() ??
                          '0') ??
                      0;
                  int countBins = int.tryParse(item['count_bins']?.toString() ??
                          item['COUNT_BINS']?.toString() ??
                          '0') ??
                      0;

                  String upDate = item['up_date']?.toString().trim() ??
                      item['UP_DATE']?.toString().trim() ??
                      '';
                  String upTime = item['up_time']?.toString().trim() ??
                      item['UP_TIME']?.toString().trim() ??
                      '';

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

                  String rawSt = item['st']?.toString().trim() ??
                      item['ST']?.toString().trim() ??
                      'Dry';
                  String st = rawSt.isEmpty ? 'Dry' : rawSt;

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

              const List<String> preferredStOrder = ['Dry', 'Cold'];
              final sortedStList = stSet.toList()
                ..sort((a, b) => sortWithPreferredOrder(a, b, preferredStOrder));

              final now = DateTime.now();

              final dashboardMessage = ChatMessage(
                text: "Annual Physical Inventory",
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
                _scrollToBottom();
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
            _scrollToBottom();
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
            _scrollToBottom();
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

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, color: Color(0xFF8045DD), size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Select a Quick Report",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF303489),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGridActionItem("Overall Progress", Icons.analytics_rounded, const Color(0xFF303489)),
                  _buildGridActionItem("Riyadh", Icons.location_city_rounded, const Color(0xFF8045DD)),
                  _buildGridActionItem("Jeddah", Icons.location_city_rounded, const Color(0xFF2659E4)),
                  _buildGridActionItem("Dammam", Icons.location_city_rounded, const Color(0xFF3CCEFF)),
                  _buildGridActionItem("Khamis", Icons.location_city_rounded, const Color(0xFF33333D)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridActionItem(String actionName, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _triggerReportAction(actionName);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            actionName == "Overall Progress" ? actionName : actionName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF33333D),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _triggerReportAction(String actionName) async {
    setState(() {
      _typingText = "Salma is preparing the report for you";
      _isTyping = true;
    });

    String bearerToken =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTk2MzIiLCJuYW1lIjoiQWhtZWQgU2FiZXIiLCJhZG1pbiI6dHJ1ZSwiaXNfc2FiZXIiOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.ULGyy3ePlq0QEGjMDRJzT7Jop7TQ4Rjw3Bp6TcFdTkM';

    try {
      final response = await http.get(
        Uri.parse(
          'https://n8n.srv1348343.hstgr.cloud/webhook/physical_inventory',
        ).replace(queryParameters: {
          'imessage': 'overall progress',
          'employee_id': widget.employeeId,
        }),
        headers: {'authorization': bearerToken},
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty && data.first is Map) {
            List<Map<String, dynamic>> parsedItems = [];
            Set<String> branchSet = {};
            Set<String> segmentSet = {};
            Set<String> stSet = {};
            Set<String> dateSet = {};

            int idx = 1;
            for (var item in data) {
              if (item is Map) {
                String branch = item['branch']?.toString().trim() ??
                    item['BRANCH']?.toString().trim() ??
                    'Unknown Branch';
                String segment = item['segment']?.toString().trim() ??
                    item['SEGMENT']?.toString().trim() ??
                    'General';
                int bins = int.tryParse(item['bins']?.toString() ??
                        item['BINS']?.toString() ??
                        '0') ??
                    0;
                int countBins = int.tryParse(item['count_bins']?.toString() ??
                        item['COUNT_BINS']?.toString() ??
                        '0') ??
                    0;

                String upDate = item['up_date']?.toString().trim() ??
                    item['UP_DATE']?.toString().trim() ??
                    '';
                String upTime = item['up_time']?.toString().trim() ??
                    item['UP_TIME']?.toString().trim() ??
                    '';

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
                  int hourInt = 8 + (idx % 9);
                  hourLabel = "${hourInt.toString().padLeft(2, '0')}:00";
                }

                String rawSt = item['st']?.toString().trim() ??
                    item['ST']?.toString().trim() ??
                    'Dry';
                String st = rawSt.isEmpty ? 'Dry' : rawSt;

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

            const List<String> preferredStOrder = ['Dry', 'Cold'];
            final sortedStList = stSet.toList()
              ..sort((a, b) => sortWithPreferredOrder(a, b, preferredStOrder));

            final now = DateTime.now();

            if (mounted) {
              setState(() {
                if (actionName == "Overall Progress") {
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
                  _messages.insert(0, dashboardMessage);
                } else {
                  String matchedBranch = branchSet.firstWhere(
                    (br) => br.toLowerCase().contains(actionName.toLowerCase()),
                    orElse: () => actionName == "Khamis" ? "Khamis Mushait" : actionName,
                  );

                  final branchReportMessage = ChatMessage(
                    text: matchedBranch,
                    isUser: false,
                    timestamp: now,
                    type: ChatMessageType.branchReportCard,
                    chartData: {
                      'rawItems': parsedItems,
                      'branchName': matchedBranch,
                    },
                  );
                  _messages.insert(0, branchReportMessage);
                }

                // Insert dynamic AI Insight message right after the report
                final insightText = _generateAiInsight(actionName, parsedItems, branchSet);
                final insightMessage = ChatMessage(
                  text: insightText,
                  isUser: false,
                  timestamp: now.add(const Duration(milliseconds: 50)),
                  type: ChatMessageType.text,
                );
                _messages.insert(0, insightMessage);
              });
              _saveMessages();
              _scrollToBottom();
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _messages.insert(
                0,
                ChatMessage(
                  text: "Failed to parse report data.",
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
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

  String _generateAiInsight(String actionName, List<Map<String, dynamic>> items, Set<String> branchSet) {
    if (items.isEmpty) return "💡 Salma's Insight: Inventory data is synchronized and ready for counting execution.";

    int totalB = items.fold<int>(0, (s, e) => s + (e['bins'] as int));
    int totalC = items.fold<int>(0, (s, e) => s + (e['countBins'] as int));
    int remainingBins = totalB - totalC;
    double overallP = totalB > 0 ? (totalC / totalB) * 100 : 0.0;

    String timeEstimate = "N/A";
    final random = math.Random();
    if (actionName == "Overall Progress") {
      if (overallP == 0.0) {
        final List<String> zeroPhrases = [
          "💡 Salma's Insight: Physical inventory counting has not started yet across active warehouses. 0 bins have been counted so far out of $totalB total bins.",
          "💡 Salma's Insight: Physical inventory execution is currently pending; physical inventory has not initiated yet. Total pending count stands at $totalB bins.",
          "💡 Salma's Insight: No counting activity recorded yet. Physical inventory counting has not started across the system."
        ];
        return zeroPhrases[random.nextInt(zeroPhrases.length)];
      }

      Map<String, double> hourlyRates = {};
      for (var item in items) {
        String time = item['time']?.toString() ?? '08:00';
        int cBins = item['countBins'] as int? ?? 0;
        hourlyRates[time] = (hourlyRates[time] ?? 0.0) + cBins.toDouble();
      }

      double avgBinsPerHour = 0.0;
      if (hourlyRates.isNotEmpty) {
        double sumVals = hourlyRates.values.fold(0.0, (a, b) => a + b);
        avgBinsPerHour = sumVals / hourlyRates.length;
      }

      double hoursRemaining = avgBinsPerHour > 0 ? remainingBins / avgBinsPerHour : 0.0;
      timeEstimate = hoursRemaining > 0 
          ? (hoursRemaining < 1 ? "${(hoursRemaining * 60).toInt()} minutes" : "${hoursRemaining.toStringAsFixed(1)} hours")
          : "N/A";

      final List<String> overallPhrases = [
        "💡 Salma's Insight: Current overall counting execution stands at ${overallP.toStringAsFixed(1)}%. There are $remainingBins bins remaining to complete. At an average velocity of ${avgBinsPerHour.toInt()} bins/hour, we estimate approximately $timeEstimate remaining to finish all active inventories.",
        "💡 Salma's Insight: Inventory progress report is at ${overallP.toStringAsFixed(1)}% completion with $remainingBins bins left. Based on scanning speeds of ~${avgBinsPerHour.toInt()} bins per hour, estimated time to completion is around $timeEstimate.",
        "💡 Salma's Insight: Execution tracking shows ${overallP.toStringAsFixed(1)}% overall completion ($remainingBins bins pending). Maintaining the current hourly average of ${avgBinsPerHour.toInt()} bins, full inventory closure is projected in roughly $timeEstimate."
      ];
      return overallPhrases[random.nextInt(overallPhrases.length)];
    } else {
      final bItems = items.where((i) => i['branch']?.toString().toLowerCase().contains(actionName.toLowerCase()) == true).toList();
      int bB = bItems.fold<int>(0, (s, e) => s + (e['bins'] as int));
      int bC = bItems.fold<int>(0, (s, e) => s + (e['countBins'] as int));
      int bRem = bB - bC;
      double bP = bB > 0 ? (bC / bB) * 100 : 0.0;

      if (bP == 0.0) {
        final List<String> branchZeroPhrases = [
          "💡 Salma's Insight: Physical inventory has not started yet in $actionName branch. All $bB designated bins are pending initial audit verification.",
          "💡 Salma's Insight: Counting activity for $actionName is currently at 0%. Physical inventory has not initiated yet in this warehouse.",
          "💡 Salma's Insight: No bins scanned yet for $actionName. Physical inventory has not started yet in this branch."
        ];
        return branchZeroPhrases[random.nextInt(branchZeroPhrases.length)];
      }

      Map<String, double> bHourly = {};
      for (var item in bItems) {
        String time = item['time']?.toString() ?? '08:00';
        int cBins = item['countBins'] as int? ?? 0;
        bHourly[time] = (bHourly[time] ?? 0.0) + cBins.toDouble();
      }
      double bAvg = bHourly.isNotEmpty ? bHourly.values.fold(0.0, (a, b) => a + b) / bHourly.length : 10.0;
      double bRemHours = bAvg > 0 ? bRem / bAvg : 0.0;
      String bTimeEst = bRemHours > 0 
          ? (bRemHours < 1 ? "${(bRemHours * 60).toInt()} minutes" : "${bRemHours.toStringAsFixed(1)} hours")
          : timeEstimate;

      final List<String> specificBranchPhrases = [
        "💡 Salma's Insight: $actionName report shows ${bP.toStringAsFixed(1)}% completion with $bRem bins remaining. Operating at an average of ${bAvg.toInt()} bins per hour, estimated time to completion is $bTimeEst.",
        "💡 Salma's Insight: $actionName branch execution is at ${bP.toStringAsFixed(1)}% ($bRem bins left to scan). Based on hourly velocity of ~${bAvg.toInt()} bins/hour, projected completion is in $bTimeEst.",
        "💡 Salma's Insight: Physical inventory progress for $actionName stands at ${bP.toStringAsFixed(1)}% ($bRem bins pending). At current counting speeds of ${bAvg.toInt()} bins per hour, we project completion in approximately $bTimeEst."
      ];
      return specificBranchPhrases[random.nextInt(specificBranchPhrases.length)];
    }
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
                  'assets/images/salma_physical_inventory_avatar.jpeg',
                  'Physical Inventory Agent',
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: const AssetImage(
                  'assets/images/salma_physical_inventory_avatar.jpeg',
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
          // 1. Action button outside text area (left) - neutral without color
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFF33333D), size: 26),
            onPressed: _showActionMenu,
            tooltip: 'Quick Reports',
          ),
          const SizedBox(width: 4.0),

          // 2. White rounded text input bubble (middle)
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

          // 3. Send button in dark black circle outside text area (right)
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
                      'assets/images/salma_physical_inventory_avatar.jpeg',
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
