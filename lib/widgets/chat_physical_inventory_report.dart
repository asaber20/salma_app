import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/chat_message.dart';

const List<Color> kChartPalette = [
  Color(0xFF8045DD), // Purple
  Color(0xFF2659E4), // Royal Blue
  Color(0xFF3CCEFF), // Sky Blue
  Color(0xFF303489), // Deep Navy
  Color(0xFF33333D), // Dark Charcoal
];

const List<String> kPreferredBranchOrder = [
  'Riyadh',
  'Dammam',
  'Jeddah',
  'Khamis Mushait',
];

const List<String> kPreferredSegmentOrder = [
  'Human Pharma',
  'Pharma',
  'Animal Health',
  'Animal health',
  'Health tech',
];

int kSortWithPreferredOrder(String a, String b, List<String> preferredOrder) {
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

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isDashboard = message.type == ChatMessageType.physicalDashboard ||
        message.type == ChatMessageType.branchReportCard;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDashboard
              ? MediaQuery.of(context).size.width * 0.96
              : MediaQuery.of(context).size.width * 0.88,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: 4,
            horizontal: isDashboard ? 2 : 8,
          ),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isDashboard ? 12 : 14,
          ),
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
              else if (message.type == ChatMessageType.branchReportCard)
                BranchReportCardWidget(
                  chartData: message.chartData ?? {},
                  branchName: message.chartData?['branchName'] ?? 'Branch',
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
    const double bottomPadding = 45.0;

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
        style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF33333D),
            fontWeight: FontWeight.w600),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x, size.height - bottomPadding + 6);
      canvas.rotate(-math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width, -textPainter.height / 2),
      );
      canvas.restore();
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
          height: 205,
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
  String _selectedSt = 'All';

  List<Map<String, dynamic>> _getRawItems() {
    final List raw = widget.chartData['rawItems'] as List? ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _buildExecutiveKpiBanner(List<Map<String, dynamic>> rawItems, List<String> branches) {
    int totalBins = rawItems.fold<int>(0, (sum, e) => sum + (e['bins'] as int));
    int totalCounted = rawItems.fold<int>(0, (sum, e) => sum + (e['countBins'] as int));
    double overallPct = totalBins > 0 ? (totalCounted / totalBins) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF303489), Color(0xFF8045DD)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF303489).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKpiItem("Total Bins", "$totalBins", Icons.inventory_2_rounded),
          _buildKpiItem("Counted", "$totalCounted", Icons.check_circle_rounded),
          _buildKpiItem("Progress", "${overallPct.toStringAsFixed(1)}%", Icons.trending_up_rounded),
          _buildKpiItem("Branches", "${branches.length}", Icons.business_rounded),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawItems = _getRawItems();

    final List<String> rawBranches =
        (widget.chartData['branches'] as List? ?? []).map((e) => e.toString()).toList()
          ..sort((a, b) => kSortWithPreferredOrder(a, b, kPreferredBranchOrder));

    final List<String> rawSegments =
        (widget.chartData['segments'] as List? ?? []).map((e) => e.toString()).toList()
          ..sort((a, b) => kSortWithPreferredOrder(a, b, kPreferredSegmentOrder));

    final List<String> rawStList =
        (widget.chartData['stList'] as List? ?? []).map((e) => e.toString()).toList();

    final List<String> availableBranches = ['All', ...rawBranches];
    final List<String> availableSegments = ['All', ...rawSegments];
    final List<String> availableStList =
        ['All', ...(rawStList.isNotEmpty ? rawStList : ['Dry', 'Cold'])];

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

        // Executive Summary KPI Banner
        _buildExecutiveKpiBanner(rawItems, rawBranches),
        const SizedBox(height: 16),

        // Active Filter Summary & Reset Button
        if (_selectedBranch != 'All' ||
            _selectedSegment != 'All' ||
            _selectedSt != 'All')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF303489).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF303489).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFF303489)),
                    const SizedBox(width: 6),
                    Text(
                      "Filtered by: "
                      "${_selectedBranch != 'All' ? 'Branch: $_selectedBranch ' : ''}"
                      "${_selectedSegment != 'All' ? 'Segment: $_selectedSegment ' : ''}"
                      "${_selectedSt != 'All' ? 'Storage: $_selectedSt' : ''}",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBranch = 'All';
                      _selectedSegment = 'All';
                      _selectedSt = 'All';
                    });
                  },
                  child: const Text(
                    "Reset All",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
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

        // 2. Progress by Segment & Storage Condition Side-by-Side
        _buildSegmentAndStorageSection(
          context,
          rawItems,
          availableSegments.sublist(1),
          availableStList.sublist(1),
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
                final st = item['st']?.toString() ?? '';

                final matchesB = b == branchName;
                final matchesS = _selectedSegment == 'All' || s == _selectedSegment;
                final matchesSt = _selectedSt == 'All' || st == _selectedSt;

                return matchesB && matchesS && matchesSt;
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
                      setState(() {
                        if (_selectedBranch == branchName) {
                          _selectedBranch = 'All';
                        } else {
                          _selectedBranch = branchName;
                        }
                      });
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

  Widget _buildSegmentAndStorageSection(
      BuildContext context, List<Map<String, dynamic>> rawItems, List<String> segmentList, List<String> stList) {
    if (segmentList.isEmpty && stList.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segment Section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Progress by Segment",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF303489)),
                    ),
                    if (_selectedSegment != 'All')
                      InkWell(
                        onTap: () => setState(() => _selectedSegment = 'All'),
                        child: const Text("Clear", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...segmentList.asMap().entries.map((sEntry) {
                  final int segIdx = sEntry.key;
                  final String segmentName = sEntry.value;
                  final Color segColor = kChartPalette[segIdx % kChartPalette.length];

                  final matchingItems = rawItems.where((item) {
                    final b = item['branch']?.toString() ?? '';
                    final s = item['segment']?.toString() ?? '';
                    final st = item['st']?.toString() ?? '';

                    final matchesS = s == segmentName;
                    final matchesB = _selectedBranch == 'All' || b == _selectedBranch;
                    final matchesSt = _selectedSt == 'All' || st == _selectedSt;

                    return matchesS && matchesB && matchesSt;
                  }).toList();

                  int totalBins = matchingItems.fold<int>(0, (sum, e) => sum + (e['bins'] as int));
                  int totalCounted = matchingItems.fold<int>(0, (sum, e) => sum + (e['countBins'] as int));
                  double percentage = totalBins > 0 ? (totalCounted / totalBins) : 0.0;
                  int pctInt = (percentage * 100).round();
                  bool isSel = _selectedSegment == segmentName;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedSegment == segmentName) {
                            _selectedSegment = 'All';
                          } else {
                            _selectedSegment = segmentName;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: isSel ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isSel ? segColor.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    segmentName,
                                    style: TextStyle(
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 11,
                                        color: const Color(0xFF33333D)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$pctInt%",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: segColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage.clamp(0.0, 1.0),
                                minHeight: 6,
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
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Storage Section
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Progress by Storage",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF303489)),
                    ),
                    if (_selectedSt != 'All')
                      InkWell(
                        onTap: () => setState(() => _selectedSt = 'All'),
                        child: const Text("Clear", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...stList.asMap().entries.map((stEntry) {
                  final int stIdx = stEntry.key;
                  final String stName = stEntry.value;
                  final Color stColor = kChartPalette[(stIdx + 2) % kChartPalette.length];

                  final matchingItems = rawItems.where((item) {
                    final b = item['branch']?.toString() ?? '';
                    final s = item['segment']?.toString() ?? '';
                    final st = item['st']?.toString() ?? '';

                    final matchesSt = st == stName;
                    final matchesB = _selectedBranch == 'All' || b == _selectedBranch;
                    final matchesS = _selectedSegment == 'All' || s == _selectedSegment;

                    return matchesSt && matchesB && matchesS;
                  }).toList();

                  int totalBins = matchingItems.fold<int>(0, (sum, e) => sum + (e['bins'] as int));
                  int totalCounted = matchingItems.fold<int>(0, (sum, e) => sum + (e['countBins'] as int));
                  double percentage = totalBins > 0 ? (totalCounted / totalBins) : 0.0;
                  int pctInt = (percentage * 100).round();
                  bool isSel = _selectedSt == stName;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedSt == stName) {
                            _selectedSt = 'All';
                          } else {
                            _selectedSt = stName;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: isSel ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isSel ? stColor.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    stName,
                                    style: TextStyle(
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 11,
                                        color: const Color(0xFF33333D)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$pctInt%",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: stColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(stColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BranchReportCardWidget extends StatefulWidget {
  final Map<String, dynamic> chartData;
  final String branchName;

  const BranchReportCardWidget({
    super.key,
    required this.chartData,
    required this.branchName,
  });

  @override
  State<BranchReportCardWidget> createState() => _BranchReportCardWidgetState();
}

class _BranchReportCardWidgetState extends State<BranchReportCardWidget> {
  String? _selectedDate;
  bool _isExpanded = true;
  String? _selectedSegmentFilter;
  String? _selectedStFilter;

  @override
  void initState() {
    super.initState();
    _selectedDate = 'All';
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

  @override
  Widget build(BuildContext context) {
    final List rawItems = widget.chartData['rawItems'] as List? ?? [];
    final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Filter items for this branch
    final branchItemsAll = items.where((item) {
      final b = item['branch']?.toString().trim().toLowerCase() ?? '';
      final target = widget.branchName.trim().toLowerCase();
      if (target.contains('khamis') && b.contains('khamis')) {
        return true;
      }
      return b == target;
    }).toList();

    Set<String> branchDates = {};
    for (var item in branchItemsAll) {
      String d = item['date']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
      branchDates.add(d);
    }
    final sortedDates = branchDates.toList()..sort();
    final List<String> availableDates = ['All', ...sortedDates];
    _selectedDate ??= 'All';

    int totalBins = branchItemsAll.fold<int>(0, (sum, e) => sum + (e['bins'] as int));
    int totalCounted = branchItemsAll.fold<int>(0, (sum, e) => sum + (e['countBins'] as int));
    double branchPct = totalBins > 0 ? (totalCounted / totalBins) : 0.0;
    int branchPctInt = (branchPct * 100).round();

    // Health Status Badge calculation
    String healthStatus = "On Track";
    Color healthColor = const Color(0xFF2E7D32);
    IconData healthIcon = Icons.trending_up_rounded;

    if (branchPct >= 1.0) {
      healthStatus = "Completed (100%)";
      healthColor = const Color(0xFF00BFA5);
      healthIcon = Icons.check_circle_rounded;
    } else if (branchPct >= 0.75) {
      healthStatus = "On Track";
      healthColor = const Color(0xFF2E7D32);
      healthIcon = Icons.trending_up_rounded;
    } else if (branchPct > 0.0) {
      healthStatus = "In Progress";
      healthColor = const Color(0xFFF57F17);
      healthIcon = Icons.hourglass_top_rounded;
    } else {
      healthStatus = "Not Started (0%)";
      healthColor = const Color(0xFFE65100);
      healthIcon = Icons.pause_circle_rounded;
    }

    // Segment breakdown for this branch (all dates)
    Map<String, Map<String, int>> segmentBreakdown = {};
    for (var item in branchItemsAll) {
      String seg = item['segment']?.toString() ?? 'General';
      int b = item['bins'] as int;
      int c = item['countBins'] as int;
      segmentBreakdown.putIfAbsent(seg, () => {'bins': 0, 'countBins': 0});
      segmentBreakdown[seg]!['bins'] = segmentBreakdown[seg]!['bins']! + b;
      segmentBreakdown[seg]!['countBins'] = segmentBreakdown[seg]!['countBins']! + c;
    }

    // Storage condition breakdown for this branch (all dates)
    Map<String, Map<String, int>> stBreakdown = {};
    for (var item in branchItemsAll) {
      String st = item['st']?.toString() ?? 'Dry';
      int b = item['bins'] as int;
      int c = item['countBins'] as int;
      stBreakdown.putIfAbsent(st, () => {'bins': 0, 'countBins': 0});
      stBreakdown[st]!['bins'] = stBreakdown[st]!['bins']! + b;
      stBreakdown[st]!['countBins'] = stBreakdown[st]!['countBins']! + c;
    }

    // Filter items by selected date specifically for hourly breakdown
    final branchItemsDateFiltered = branchItemsAll.where((item) {
      if (_selectedDate == 'All' || _selectedDate == null) return true;
      String d = item['date']?.toString() ?? '';
      return d == _selectedDate;
    }).toList();

    // Apply interactive segment / storage filters if active
    var hourlyItems = branchItemsDateFiltered;
    if (_selectedSegmentFilter != null) {
      hourlyItems = hourlyItems.where((i) => i['segment']?.toString() == _selectedSegmentFilter).toList();
    }
    if (_selectedStFilter != null) {
      hourlyItems = hourlyItems.where((i) => i['st']?.toString() == _selectedStFilter).toList();
    }

    // Hourly breakdown
    Map<String, double> branchHourly = {};
    for (var item in hourlyItems) {
      String time = item['time']?.toString() ?? '08:00';
      int cBins = item['countBins'] as int? ?? 0;
      branchHourly[time] = (branchHourly[time] ?? 0.0) + cBins.toDouble();
    }
    final sortedHours = branchHourly.keys.toList()..sort();

    String peakHour = 'N/A';
    double maxBins = -1;
    branchHourly.forEach((h, val) {
      if (val > maxBins) {
        maxBins = val;
        peakHour = h;
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header with Branch Name, Health Badge & Expand/Collapse Accordion
          Row(
            children: [
              const Icon(Icons.location_city_rounded, color: Color(0xFF303489), size: 16),
              const SizedBox(width: 6),
              Text(
                widget.branchName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF303489),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: healthColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(healthIcon, size: 12, color: healthColor),
                    const SizedBox(width: 4),
                    Text(
                      healthStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: const Color(0xFF303489),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Main 3-in-Row Layout (Progress Circle | Interactive Segments | Interactive Storage)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress Circle
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: branchPct.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8045DD)),
                    ),
                    Text(
                      "$branchPctInt%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF303489),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 60, color: Colors.grey.shade300),
              const SizedBox(width: 12),

              // Segment Progress Bars (Interactive Filter)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Segments",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF303489)),
                        ),
                        if (_selectedSegmentFilter != null)
                          InkWell(
                            onTap: () => setState(() => _selectedSegmentFilter = null),
                            child: const Text("Clear", style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (segmentBreakdown.isEmpty)
                      const Text("No data", style: TextStyle(fontSize: 10, color: Colors.grey))
                    else
                      ...segmentBreakdown.entries.map((e) {
                        String seg = e.key;
                        int b = e.value['bins']!;
                        int c = e.value['countBins']!;
                        double p = b > 0 ? (c / b) : 0.0;
                        int pInt = (p * 100).round();
                        bool isSel = _selectedSegmentFilter == seg;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSegmentFilter = isSel ? null : seg;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: isSel ? 4 : 0),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF2659E4).withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(seg, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: Color(0xFF33333D)), overflow: TextOverflow.ellipsis)),
                                    Text("$pInt%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2659E4))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                LinearProgressIndicator(
                                  value: p.clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2659E4)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 60, color: Colors.grey.shade300),
              const SizedBox(width: 12),

              // Storage Condition Progress Bars (Interactive Filter)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Storage",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF303489)),
                        ),
                        if (_selectedStFilter != null)
                          InkWell(
                            onTap: () => setState(() => _selectedStFilter = null),
                            child: const Text("Clear", style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (stBreakdown.isEmpty)
                      const Text("No data", style: TextStyle(fontSize: 10, color: Colors.grey))
                    else
                      ...stBreakdown.entries.map((e) {
                        String st = e.key;
                        int b = e.value['bins']!;
                        int c = e.value['countBins']!;
                        double p = b > 0 ? (c / b) : 0.0;
                        int pInt = (p * 100).round();
                        bool isSel = _selectedStFilter == st;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStFilter = isSel ? null : st;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: isSel ? 4 : 0),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF8045DD).withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(st, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: Color(0xFF33333D)), overflow: TextOverflow.ellipsis)),
                                    Text("$pInt%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8045DD))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                LinearProgressIndicator(
                                  value: p.clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8045DD)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),

          // 3. Expandable Accordion (Peak Hour Highlight & Date Filters)
          if (_isExpanded) ...[
            if (sortedHours.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Counted Bins Per Hour",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF303489)),
                  ),
                  if (maxBins > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8045DD).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "⚡ Peak: $peakHour (${maxBins.toInt()} bins)",
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8045DD)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sortedHours.map((h) {
                    double val = branchHourly[h]!;
                    double hourPct = totalBins > 0 ? (val / totalBins) * 100 : 0.0;
                    bool isPeak = h == peakHour;
                    return Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPeak ? const Color(0xFF8045DD).withValues(alpha: 0.12) : const Color(0xFF303489).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPeak ? const Color(0xFF8045DD) : const Color(0xFF303489).withValues(alpha: 0.15),
                          width: isPeak ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            h,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPeak ? const Color(0xFF8045DD) : const Color(0xFF303489)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${val.toInt()} bins",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8045DD)),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "${hourPct.toStringAsFixed(1)}%",
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2659E4)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (sortedDates.length > 1) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                "Filter by Date:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF303489)),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableDates.map((dateKey) {
                    final isSelected = dateKey == _selectedDate;
                    final displayDate = dateKey == 'All' ? 'All' : _formatDateLabel(dateKey);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(
                          displayDate,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF33333D),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF303489),
                        backgroundColor: Colors.grey.shade100,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
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
          ],
        ],
      ),
    );
  }
}
