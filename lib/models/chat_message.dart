enum MessageStatus { sending, sent, failed }

enum ChatMessageType {
  text,
  barChart,
  progressCircle,
  branchProgress,
  segmentProgress,
  lineChart,
  physicalDashboard,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  MessageStatus status;
  final ChatMessageType type;
  final Map<String, dynamic>? chartData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = ChatMessageType.text,
    this.chartData,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'type': type.index,
      'chartData': chartData,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int typeIdx = json['type'] ?? 0;
    ChatMessageType messageType =
        (typeIdx >= 0 && typeIdx < ChatMessageType.values.length)
            ? ChatMessageType.values[typeIdx]
            : ChatMessageType.text;

    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] != null
          ? MessageStatus.values[json['status']]
          : MessageStatus.sent,
      type: messageType,
      chartData: json['chartData'],
    );
  }
}
