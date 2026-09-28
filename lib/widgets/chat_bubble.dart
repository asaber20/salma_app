import 'package:flutter/material.dart';
import '../models/chat_message.dart';

const List<Color> kChartPalette = [
  Color(0xFF8045DD), // Purple
  Color(0xFF2659E4), // Royal Blue
  Color(0xFF3CCEFF), // Sky Blue
  Color(0xFF303489), // Deep Navy
  Color(0xFF33333D), // Dark Charcoal
];

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: message.isUser ? const Color(0xFFDCF8C6) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft:
                  message.isUser ? const Radius.circular(12) : Radius.zero,
              bottomRight:
                  message.isUser ? Radius.zero : const Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == ChatMessageType.text)
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF33333D)),
                )
              else if (message.type == ChatMessageType.physicalDashboard)
                PhysicalInventoryDashboardWidget(
                  chartData: message.chartData ?? {},
                  title: message.text,
                )
              else if (message.type == ChatMessageType.barChart)
                _buildBarChart(context)
              else if (message.type == ChatMessageType.progressCircle)
                _buildProgressCircle(context)
              else if (message.type == ChatMessageType.branchProgress)
                _buildBranchProgress(context)
              else if (message.type == ChatMessageType.segmentProgress)
                _buildSegmentProgress(context)
              else if (message.type == ChatMessageType.lineChart)
                _buildLineChart(context),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (message.isUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == MessageStatus.sent
                          ? Icons.done_all
                          : Icons.check,
                      size: 16,
                      color: message.status == MessageStatus.sent
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchProgress(BuildContext context) {
    if (message.chartData == null) return const SizedBox.shrink();
    final branches =
        message.chartData!['branches'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.business_rounded,
                color: Color(0xFF303489), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF303489),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...branches.entries.map((entry) {
          final branchName = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final int bins = (stats['bins'] ?? 0).toInt();
          final int countBins = (stats['countBins'] ?? 0).toInt();
          final double percentage = (stats['percentage'] ??
                  (bins > 0 ? countBins / bins : 0.0))
              .toDouble();
          final int pctInt = (percentage * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      branchName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF33333D)),
                    ),
                    Text(
                      "$countBins / $bins bins ($pctInt%)",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF8045DD)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2659E4)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSegmentProgress(BuildContext context) {
    if (message.chartData == null) return const SizedBox.shrink();
    final segments =
        message.chartData!['segments'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart_outline_rounded,
                color: Color(0xFF303489), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF303489),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...segments.entries.map((entry) {
          final segmentLabel = entry.key;
          final stats = entry.value as Map<String, dynamic>;
          final int bins = (stats['bins'] ?? 0).toInt();
          final int countBins = (stats['countBins'] ?? 0).toInt();
          final double percentage = (stats['percentage'] ??
                  (bins > 0 ? countBins / bins : 0.0))
              .toDouble();
          final int pctInt = (percentage * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        segmentLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF33333D)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$countBins / $bins ($pctInt%)",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF2659E4)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2659E4)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context) {
    if (message.chartData == null) return const SizedBox.shrink();

    final Map<String, dynamic> hourlyByDate =
        message.chartData!['hourlyByDate'] as Map<String, dynamic>? ??
            {
              'Today':
                  message.chartData!['hourly'] as Map<String, dynamic>? ?? {}
            };

    return DateHourlyLineChartWidget(
      hourlyByDate: hourlyByDate,
      title: message.text,
    );
  }

  Widget _buildBarChart(BuildContext context) {
    if (message.chartData == null) return const SizedBox.shrink();

    final data = message.chartData!;
    final maxValue = data.values.fold<double>(
      0,
      (max, v) => v > max ? v.toDouble() : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF303489),
          ),
        ),
        const SizedBox(height: 12),
        ...data.entries.map((entry) {
          final label = entry.key;
          final value = entry.value.toDouble();
          final percentage = maxValue > 0 ? value / maxValue : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF33333D),
                      ),
                    ),
                    Text(
                      "${value.toInt()}M",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF303489), Color(0xFF8045DD)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProgressCircle(BuildContext context) {
    if (message.chartData == null) return const SizedBox.shrink();

    final percentage = message.chartData!['percentage']?.toDouble() ?? 0.0;
    final label = message.chartData!['label'] ?? "Achievement";

    return Column(
      children: [
        Text(
          message.text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF303489),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF8045DD),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(percentage * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF303489),
                    ),
                  ),
                  Text(
                    "Target",
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF33333D)),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class HourlyLineChartPainter extends CustomPainter {
  final Map<String, double> hourlyData;

  HourlyLineChartPainter(this.hourlyData);

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyData.isEmpty) return;

    const double leftPadding = 30.0;
    const double rightPadding = 20.0;
    const double topPadding = 25.0;
    const double bottomPadding = 30.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final values = hourlyData.values.toList();
    final keys = hourlyData.keys.toList();

    final double maxVal =
        values.fold<double>(0, (max, v) => v > max ? v : max);
    final double effectiveMax = maxVal == 0 ? 10.0 : maxVal * 1.25;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const int gridCount = 3;
    for (int i = 0; i <= gridCount; i++) {
      double y = topPadding + chartHeight - (i / gridCount) * chartHeight;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      double labelVal = (i / gridCount) * effectiveMax;
      textPainter.text = TextSpan(
        text: labelVal.toInt().toString(),
        style: const TextStyle(fontSize: 10, color: Color(0xFF33333D)),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            leftPadding - textPainter.width - 4, y - textPainter.height / 2),
      );
    }

    List<Offset> points = [];
    double xStep = keys.length > 1
        ? chartWidth / (keys.length - 1)
        : chartWidth / 2;

    for (int i = 0; i < keys.length; i++) {
      double x =
          leftPadding + (keys.length > 1 ? i * xStep : chartWidth / 2);
      double y = topPadding +
          chartHeight -
          (values[i] / effectiveMax) * chartHeight;
      points.add(Offset(x, y));

      textPainter.text = TextSpan(
        text: keys[i],
        style: const TextStyle(fontSize: 10, color: Color(0xFF33333D), fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    if (points.length > 1) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      final Path fillPath = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlP1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlP2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);

        path.cubicTo(
          controlP1.dx,
          controlP1.dy,
          controlP2.dx,
          controlP2.dy,
          p2.dx,
          p2.dy,
        );
        fillPath.cubicTo(
          controlP1.dx,
          controlP1.dy,
          controlP2.dx,
          controlP2.dy,
          p2.dx,
          p2.dy,
        );
      }

      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.lineTo(points.first.dx, topPadding + chartHeight);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3CCEFF).withValues(alpha: 0.35),
            const Color(0xFF2659E4).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTRB(
            leftPadding,
            topPadding,
            size.width - rightPadding,
            topPadding + chartHeight,
          ),
        );

      canvas.drawPath(fillPath, fillPaint);

      final Paint strokePaint = Paint()
        ..color = const Color(0xFF2659E4)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);
    }

    final Paint dotPaint = Paint()..color = const Color(0xFF303489);
    final Paint whiteInnerPaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5.0, dotPaint);
      canvas.drawCircle(points[i], 2.5, whiteInnerPaint);

      textPainter.text = TextSpan(
        text: values[i].toInt().toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF303489),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HourlyLineChartPainter oldDelegate) => true;
}

class DateHourlyLineChartWidget extends StatefulWidget {
  final Map<String, dynamic> hourlyByDate;
  final String title;

  const DateHourlyLineChartWidget({
    super.key,
    required this.hourlyByDate,
    required this.title,
  });

  @override
  State<DateHourlyLineChartWidget> createState() =>
      _DateHourlyLineChartWidgetState();
}

class _DateHourlyLineChartWidgetState
    extends State<DateHourlyLineChartWidget> {
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.hourlyByDate.isNotEmpty) {
      _selectedDate = widget.hourlyByDate.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.hourlyByDate.keys.toList();
    if (dates.isEmpty) return const SizedBox.shrink();

    final String activeDate =
        (_selectedDate != null && dates.contains(_selectedDate))
            ? _selectedDate!
            : dates.first;

    final Map<String, dynamic> rawHours =
        widget.hourlyByDate[activeDate] as Map<String, dynamic>? ?? {};

    Map<String, double> hourlyData = {};
    final sortedHourKeys = rawHours.keys.toList()..sort();
    for (var h in sortedHourKeys) {
      hourlyData[h] = (rawHours[h] as num).toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart_rounded,
                color: Color(0xFF303489), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF303489),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dates.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates.map((dateKey) {
                final isSelected = dateKey == activeDate;
                final displayDate = _formatDateLabel(dateKey);
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF303489),
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDate = dateKey;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              "Date: ${_formatDateLabel(activeDate)}",
              style: const TextStyle(fontSize: 12, color: Color(0xFF33333D)),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          width: double.infinity,
          child: CustomPaint(
            painter: HourlyLineChartPainter(hourlyData),
          ),
        ),
      ],
    );
  }

  String _formatDateLabel(String dateStr) {
    if (dateStr.contains('-')) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    }
    return dateStr;
  }
}

class PhysicalInventoryDashboardWidget extends StatefulWidget {
  final Map<String, dynamic> chartData;
  final String title;

  const PhysicalInventoryDashboardWidget({
    super.key,
    required this.chartData,
    required this.title,
  });

  @override
  State<PhysicalInventoryDashboardWidget> createState() =>
      _PhysicalInventoryDashboardWidgetState();
}

class _PhysicalInventoryDashboardWidgetState
    extends State<PhysicalInventoryDashboardWidget> {
  String _selectedBranch = 'All';
  String _selectedSegment = 'All';
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    final List dates = widget.chartData['dates'] as List? ?? [];
    if (dates.isNotEmpty) {
      _selectedDate = dates.first.toString();
    }
  }

  List<Map<String, dynamic>> _getRawItems() {
    final List raw = widget.chartData['rawItems'] as List? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rawItems = _getRawItems();
    final List<String> availableBranches = [
      'All',
      ...(widget.chartData['branches'] as List? ?? []).map((e) => e.toString())
    ];
    final List<String> availableSegments = [
      'All',
      ...(widget.chartData['segments'] as List? ?? []).map((e) => e.toString())
    ];
    final List<String> availableDates =
        (widget.chartData['dates'] as List? ?? []).map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
        Row(
          children: [
            const Icon(Icons.analytics_rounded,
                color: Color(0xFF303489), size: 20),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF303489),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. Branch Filter
        if (availableBranches.length > 2) ...[
          Row(
            children: const [
              Icon(Icons.location_city_rounded, size: 13, color: Color(0xFF303489)),
              SizedBox(width: 4),
              Text(
                "Branch Filter:",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableBranches.map((branchName) {
                final isSelected = branchName == _selectedBranch;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(
                      branchName == 'All' ? 'All Branches' : branchName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF33333D),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF303489),
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedBranch = branchName;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 2. Segment Filter
        if (availableSegments.length > 2) ...[
          Row(
            children: const [
              Icon(Icons.category_rounded, size: 13, color: Color(0xFF8045DD)),
              SizedBox(width: 4),
              Text(
                "Segment Filter:",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8045DD)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableSegments.map((segmentName) {
                final isSelected = segmentName == _selectedSegment;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(
                      segmentName == 'All' ? 'All Segments' : segmentName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF33333D),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8045DD),
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedSegment = segmentName;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Active Filter Summary Badge
        if (_selectedBranch != 'All' || _selectedSegment != 'All')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF303489).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt_rounded, size: 14, color: Color(0xFF303489)),
                const SizedBox(width: 4),
                Text(
                  "Filters: ${_selectedBranch != 'All' ? 'Branch: $_selectedBranch' : ''}"
                  "${(_selectedBranch != 'All' && _selectedSegment != 'All') ? ' | ' : ''}"
                  "${_selectedSegment != 'All' ? 'Segment: $_selectedSegment' : ''}",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // 1. Progress Circles per Branch Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _buildBranchCirclesSection(
              context, rawItems, availableBranches.sublist(1)),
        ),

        const SizedBox(height: 20),

        // 2. Progress by Segment
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _buildSegmentSection(
              context, rawItems, availableSegments.sublist(1)),
        ),

        const SizedBox(height: 20),

        // 3. Line Chart by Date / Hour
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _buildLineChartSection(
              context, rawItems, availableDates),
        ),
      ],
    );
  }

  Widget _buildBranchCirclesSection(
      BuildContext context, List<Map<String, dynamic>> rawItems, List<String> branchList) {
    if (branchList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progress by Branch",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF303489),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: branchList.asMap().entries.map((bEntry) {
              final int branchIdx = bEntry.key;
              final String branchName = bEntry.value;
              final Color branchColor = kChartPalette[branchIdx % kChartPalette.length];

              final matchingItems = rawItems.where((item) {
                final b = item['branch']?.toString() ?? '';
                final s = item['segment']?.toString() ?? '';
                final matchesB = b == branchName;
                final matchesS = _selectedSegment == 'All' || s == _selectedSegment;
                return matchesB && matchesS;
              }).toList();

              int totalBins = matchingItems.fold<int>(0, (sum, e) => sum + (e['bins'] as int));
              int totalCounted = matchingItems.fold<int>(0, (sum, e) => sum + (e['countBins'] as int));
              double percentage = totalBins > 0 ? (totalCounted / totalBins) : 0.0;
              int pctInt = (percentage * 100).round();

              final isFilteredBranch = _selectedBranch == 'All' || _selectedBranch == branchName;

              return Opacity(
                opacity: isFilteredBranch ? 1.0 : 0.35,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: InkWell(
                    onTap: () {
                      _showBranchDetailDialog(
                          context, branchName, totalCounted, totalBins, pctInt, branchColor);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: CircularProgressIndicator(
                                  value: percentage.clamp(0.0, 1.0),
                                  strokeWidth: 7,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isFilteredBranch
                                        ? branchColor
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                "$pctInt%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: branchColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            branchName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF33333D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showBranchDetailDialog(BuildContext context, String branchName,
      int countBins, int bins, int pctInt, Color accentColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.location_city_rounded, color: accentColor),
              const SizedBox(width: 8),
              Text(branchName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF33333D))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Counted Bins:",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF33333D))),
                        Text("$countBins",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: accentColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Bins:",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF33333D))),
                        Text("$bins",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF33333D))),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Progress:",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF33333D))),
                        Text("$pctInt%",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: accentColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: _buildCloseButtonText(accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloseButtonText(Color accentColor) {
    return Text(
      "Close",
      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
    );
  }

  void _showSegmentDetailDialog(BuildContext context, String segmentName,
      int countBins, int bins, int pctInt, Color accentColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.category_rounded, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  segmentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF33333D)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Counted Bins:",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF33333D))),
                        Text("$countBins",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: accentColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Bins:",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF33333D))),
                        Text("$bins",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF33333D))),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Progress:",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF33333D))),
                        Text("$pctInt%",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: accentColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: _buildCloseButtonText(accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentSection(
      BuildContext context, List<Map<String, dynamic>> rawItems, List<String> segmentList) {
    if (segmentList.isEmpty) return const SizedBox.shrink();

    final activeSegments = _selectedSegment == 'All'
        ? segmentList
        : segmentList.where((s) => s == _selectedSegment).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progress by Segment",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF303489),
          ),
        ),
        const SizedBox(height: 12),
        if (activeSegments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("No segment data matching filters.",
                style: TextStyle(fontSize: 12, color: Color(0xFF33333D))),
          )
        else
          ...activeSegments.asMap().entries.map((sEntry) {
            final int segIdx = sEntry.key;
            final String segmentName = sEntry.value;
            final Color segColor = kChartPalette[segIdx % kChartPalette.length];

            final matchingItems = rawItems.where((item) {
              final b = item['branch']?.toString() ?? '';
              final s = item['segment']?.toString() ?? '';
              final matchesS = s == segmentName;
              final matchesB = _selectedBranch == 'All' || b == _selectedBranch;
              return matchesS && matchesB;
            }).toList();

            int totalBins = matchingItems.fold<int>(0, (sum, e) => sum + (e['bins'] as int));
            int totalCounted = matchingItems.fold<int>(0, (sum, e) => sum + (e['countBins'] as int));
            double percentage = totalBins > 0 ? (totalCounted / totalBins) : 0.0;
            int pctInt = (percentage * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                onTap: () {
                  _showSegmentDetailDialog(
                      context, segmentName, totalCounted, totalBins, pctInt, segColor);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              segmentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF33333D)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$pctInt%",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: segColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percentage.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(segColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLineChartSection(
      BuildContext context, List<Map<String, dynamic>> rawItems, List<String> dates) {
    if (dates.isEmpty && rawItems.isNotEmpty) {
      dates.add(DateTime.now().toIso8601String().split('T').first);
    }
    if (dates.isEmpty) return const SizedBox.shrink();

    final String activeDate =
        (_selectedDate != null && dates.contains(_selectedDate))
            ? _selectedDate!
            : dates.first;

    final matchingItems = rawItems.where((item) {
      final b = item['branch']?.toString() ?? '';
      final s = item['segment']?.toString() ?? '';
      final d = item['date']?.toString() ?? '';

      final matchesB = _selectedBranch == 'All' || b == _selectedBranch;
      final matchesS = _selectedSegment == 'All' || s == _selectedSegment;
      final matchesD = dates.length <= 1 || d == activeDate;

      return matchesB && matchesS && matchesD;
    }).toList();

    Map<String, double> hourlyData = {};
    for (var item in matchingItems) {
      String time = item['time']?.toString() ?? '08:00';
      int cBins = item['countBins'] as int? ?? 0;
      hourlyData[time] = (hourlyData[time] ?? 0.0) + cBins.toDouble();
    }

    final sortedHourKeys = hourlyData.keys.toList()..sort();
    Map<String, double> sortedHourlyData = {};
    for (var h in sortedHourKeys) {
      sortedHourlyData[h] = hourlyData[h]!;
    }

    if (sortedHourlyData.isEmpty) {
      sortedHourlyData = {
        '08:00': 0.0,
        '10:00': 0.0,
        '12:00': 0.0,
        '14:00': 0.0,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Progress Per Date / Hour",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF303489),
              ),
            ),
            if (dates.length <= 1)
              Text(
                "Date: ${_formatDateLabel(activeDate)}",
                style: const TextStyle(fontSize: 11, color: Color(0xFF33333D)),
              ),
          ],
        ),
        if (dates.length > 1) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates.map((dateKey) {
                final isSelected = dateKey == activeDate;
                final displayDate = _formatDateLabel(dateKey);
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF33333D),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF303489),
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDate = dateKey;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          width: double.infinity,
          child: CustomPaint(
            key: ValueKey("line_chart_${activeDate}_${_selectedBranch}_$_selectedSegment"),
            painter: HourlyLineChartPainter(sortedHourlyData),
          ),
        ),
      ],
    );
  }

  String _formatDateLabel(String dateStr) {
    if (dateStr.contains('-')) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    }
    return dateStr;
  }
}
