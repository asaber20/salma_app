import 'package:flutter/material.dart';
import 'dart:math' as math;

const List<Color> kChartPalette = [
  Color(0xFF8045DD), // Purple
  Color(0xFF2659E4), // Royal Blue
  Color(0xFF3CCEFF), // Sky Blue
  Color(0xFF303489), // Deep Navy
  Color(0xFF00BFA5), // Teal
  Color(0xFFE65100), // Orange
];

const List<String> kPreferredStockLocationOrder = [
  'Riyadh',
  'Jeddah',
  'Dammam',
  'Khamis',
];

int sortStockLocationOrder(String a, String b) {
  int idxA = kPreferredStockLocationOrder.indexWhere((p) => p.toLowerCase() == a.toLowerCase());
  int idxB = kPreferredStockLocationOrder.indexWhere((p) => p.toLowerCase() == b.toLowerCase());
  if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
  if (idxA != -1) return -1;
  if (idxB != -1) return 1;
  return a.compareTo(b);
}

class StockOverviewReportWidget extends StatefulWidget {
  final Map<String, dynamic> chartData;
  final String reportType;

  const StockOverviewReportWidget({
    super.key,
    required this.chartData,
    required this.reportType,
  });

  @override
  State<StockOverviewReportWidget> createState() => _StockOverviewReportWidgetState();
}

class _StockOverviewReportWidgetState extends State<StockOverviewReportWidget> {
  String _selectedLocationFilter = 'All';
  String? _selectedSegmentFilter;
  String? _selectedStorageFilter;
  String _selectedInsuranceStorageFilter = 'All';

  // State for Top Suppliers pagination & filters
  int _supplierDisplayLimit = 10;
  String _selectedSupplierBranchFilter = 'All';
  String? _selectedSupplierSegmentFilter;

  // State for Top Items pagination & filters
  int _itemDisplayLimit = 10;
  String _selectedItemBranchFilter = 'All';
  String? _selectedItemSegmentFilter;

  // State for Expiry Analysis filters & interactive chart
  String _selectedExpiryBranchFilter = 'All';
  String? _selectedExpirySegmentFilter;
  String? _selectedExpiryMonth;
  String? _selectedExpiryCategory; // Defaults to Near Expire

  @override
  Widget build(BuildContext context) {
    final List rawItems = widget.chartData['rawItems'] as List? ?? [];
    final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (widget.reportType == "Insurance limits") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF303489), size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Insurance Limits & Coverage",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF303489)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsuranceLimitsContent(items),
          ],
        ),
      );
    }

    if (widget.reportType == "Top Suppliers") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_rounded, color: Color(0xFF303489), size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Top Suppliers Analytics",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF303489)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTopSuppliersContent(items),
          ],
        ),
      );
    }

    if (widget.reportType == "Top Items") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFF303489), size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Top Stock Items Analytics",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF303489)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTopItemsContent(items),
          ],
        ),
      );
    }

    if (widget.reportType == "Expiry Analysis") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.event_busy_rounded, color: Color(0xFF303489), size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Stock Expiry Analysis",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF303489)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExpiryAnalysisContent(items),
          ],
        ),
      );
    }

    if (widget.reportType != "Stock overview") {
      return _buildOtherReportsContent(items, widget.reportType);
    }

    // 1. Extract unique branches (locations), hiding in-transit
    Set<String> branches = {};
    Set<String> segments = {};
    for (var item in items) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.isNotEmpty && !loc.toLowerCase().contains('transit') && !loc.toLowerCase().contains('tramsit')) {
        branches.add(loc);
      }
      String seg = item['segment']?.toString().trim() ?? '';
      if (seg.isNotEmpty) {
        segments.add(seg);
      }
    }
    final List<String> availableSegments = ['All', ...segments.toList()..sort()];

    // Filter items based on selected branch, segment, and storage
    final filteredItems = items.where((item) {
      final loc = item['location']?.toString().trim() ?? '';
      if (loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) return false;

      final seg = item['segment']?.toString().trim() ?? '';
      final st = item['storage_condition']?.toString().trim() ?? '';

      bool matchesBranch = _selectedLocationFilter == 'All' || loc == _selectedLocationFilter;
      bool matchesSeg = _selectedSegmentFilter == null || _selectedSegmentFilter == 'All' || seg == _selectedSegmentFilter;
      bool matchesSt = _selectedStorageFilter == null || _selectedStorageFilter == 'All' || st == _selectedStorageFilter;

      return matchesBranch && matchesSeg && matchesSt;
    }).toList();

    double totalStockVal = filteredItems.fold<double>(
      0.0,
      (sum, e) => sum + ((e['stock_value'] as num?)?.toDouble() ?? 0.0),
    );
    double totalValInMillions = totalStockVal / 1000000;

    // Grand total stock value across all branches (for branch ring comparison)
    double grandTotalVal = items.where((item) {
      final loc = item['location']?.toString().trim() ?? '';
      return !loc.toLowerCase().contains('transit') && !loc.toLowerCase().contains('tramsit');
    }).fold<double>(0.0, (sum, e) => sum + ((e['stock_value'] as num?)?.toDouble() ?? 0.0));

    // Aggregate by Branch (Location) for Rings
    Map<String, double> branchVals = {};
    for (var item in items) {
      final loc = item['location']?.toString().trim() ?? '';
      if (loc.isEmpty || loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) continue;
      if (_selectedSegmentFilter != null && _selectedSegmentFilter != 'All' && item['segment']?.toString() != _selectedSegmentFilter) continue;
      if (_selectedStorageFilter != null && _selectedStorageFilter != 'All' && item['storage_condition']?.toString() != _selectedStorageFilter) continue;

      double val = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
      if (val > 0) {
        branchVals[loc] = (branchVals[loc] ?? 0.0) + val;
      }
    }
    final sortedBranchVals = branchVals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Aggregate by Storage Condition
    Map<String, double> storageVals = {};
    double sumStorageVals = 0.0;
    for (var item in filteredItems) {
      String st = item['storage_condition']?.toString().trim() ?? 'Dry';
      if (st.isEmpty || st.toUpperCase() == 'NA' || st.toUpperCase() == 'N/A') continue;
      double val = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
      if (val > 0) {
        storageVals[st] = (storageVals[st] ?? 0.0) + val;
        sumStorageVals += val;
      }
    }
    final sortedStorages = storageVals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header & Total Stock Value KPI Banner
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: Color(0xFF303489), size: 18),
              const SizedBox(width: 8),
              const Text(
                "Stock Overview Analytics",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF303489),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF303489), Color(0xFF8045DD)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Total: ${totalValInMillions.toStringAsFixed(1)}M SAR",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Segment Filter Chips
          if (availableSegments.length > 1) ...[
            const Text(
              "Filter by Segment:",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                children: [
                  ...availableSegments.map((seg) {
                    final isSelected = (_selectedSegmentFilter ?? 'All') == seg;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(
                          seg == 'All' ? 'All Segments' : seg,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF33333D),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF8045DD),
                        backgroundColor: Colors.grey.shade100,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSegmentFilter = seg;
                            });
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 2. Branch Rings Section (Value per branch compared to total value)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Stock Value per Branch (Ring Progress vs Total)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
              ),
              if (_selectedLocationFilter != 'All')
                InkWell(
                  onTap: () => setState(() => _selectedLocationFilter = 'All'),
                  child: const Text("Clear Branch", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (sortedBranchVals.isEmpty)
            const Text("No branch data", style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                children: [
                  ...sortedBranchVals.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var bEntry = entry.value;
                    String branchName = bEntry.key;
                    double val = bEntry.value;
                    double valM = val / 1000000;
                    double ratio = grandTotalVal > 0 ? (val / grandTotalVal) : 0.0;
                    int ratioInt = (ratio * 100).round();
                    bool isSel = _selectedLocationFilter == branchName;
                    Color col = kChartPalette[idx % kChartPalette.length];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLocationFilter = isSel ? 'All' : branchName;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSel ? col.withValues(alpha: 0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? col : Colors.grey.shade200, width: isSel ? 1.5 : 1.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: ratio.clamp(0.0, 1.0),
                                      strokeWidth: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(col),
                                    ),
                                    Text(
                                      "$ratioInt%",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                branchName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF33333D)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${valM.toStringAsFixed(1)}M SAR",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 3. Value per Storage Conditions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Stock Value per Storage Condition",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
              ),
              if (_selectedStorageFilter != null && _selectedStorageFilter != 'All')
                InkWell(
                  onTap: () => setState(() => _selectedStorageFilter = 'All'),
                  child: const Text("Clear Storage", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (sortedStorages.isEmpty)
            const Text("No storage data", style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            ...sortedStorages.asMap().entries.map((entry) {
              int idx = entry.key;
              var stEntry = entry.value;
              String stName = stEntry.key;
              double val = stEntry.value;
              double valM = val / 1000000;
              double p = sumStorageVals > 0 ? (val / sumStorageVals) : 0.0;
              int pInt = (p * 100).round();
              bool isSel = _selectedStorageFilter == stName;
              Color col = kChartPalette[(idx + 2) % kChartPalette.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStorageFilter = isSel ? null : stName;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: isSel ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isSel ? col.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(stName, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w600, color: const Color(0xFF33333D)), overflow: TextOverflow.ellipsis)),
                            Text("${valM.toStringAsFixed(1)}M SAR ($pInt%)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        LinearProgressIndicator(
                          value: p.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(col),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _kpiBox(String label, String val) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTopSuppliersContent(List<Map<String, dynamic>> items) {
    Set<String> branches = {};
    Set<String> segments = {};
    for (var item in items) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.isNotEmpty && !loc.toLowerCase().contains('transit') && !loc.toLowerCase().contains('tramsit')) {
        branches.add(loc);
      }
      String seg = item['segment']?.toString().trim() ?? '';
      if (seg.isNotEmpty) segments.add(seg);
    }
    final sortedBranches = branches.toList()..sort(sortStockLocationOrder);
    final List<String> availableBranches = ['All', ...sortedBranches];
    final List<String> availableSegments = ['All', ...segments.toList()..sort()];

    final filteredItems = items.where((item) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) return false;

      String seg = item['segment']?.toString().trim() ?? '';
      bool matchesBranch = _selectedSupplierBranchFilter == 'All' || loc == _selectedSupplierBranchFilter;
      bool matchesSeg = _selectedSupplierSegmentFilter == null || _selectedSupplierSegmentFilter == 'All' || seg == _selectedSupplierSegmentFilter;

      return matchesBranch && matchesSeg;
    }).toList();

    Map<String, double> vendorVals = {};
    for (var item in filteredItems) {
      String vendor = item['vendor']?.toString().trim() ?? 'Unknown Vendor';
      if (vendor.isEmpty) vendor = 'Unknown Vendor';
      double val = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
      vendorVals[vendor] = (vendorVals[vendor] ?? 0.0) + val;
    }

    final sortedVendors = vendorVals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double totalVendorVal = sortedVendors.fold<double>(0.0, (s, e) => s + e.value);
    double totalM = totalVendorVal / 1000000;

    final displayedVendors = sortedVendors.take(_supplierDisplayLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF303489), Color(0xFF8045DD)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _kpiBox("Suppliers", "${sortedVendors.length}"),
              _kpiBox("Stock Value", "${totalM.toStringAsFixed(1)}M SAR"),
              _kpiBox("Showing", "${displayedVendors.length} / ${sortedVendors.length}"),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (availableBranches.length > 1) ...[
          const Text(
            "Filter by Branch:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...availableBranches.map((br) {
                  final isSelected = br == _selectedSupplierBranchFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        br == 'All' ? 'All Branches' : br,
                        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF33333D)),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF303489),
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSupplierBranchFilter = br;
                            _supplierDisplayLimit = 10;
                          });
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (availableSegments.length > 1) ...[
          const Text(
            "Filter by Segment:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...availableSegments.map((seg) {
                  final isSelected = (_selectedSupplierSegmentFilter ?? 'All') == seg;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        seg == 'All' ? 'All Segments' : seg,
                        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF33333D)),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8045DD),
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSupplierSegmentFilter = seg;
                            _supplierDisplayLimit = 10;
                          });
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        const Text(
          "Top Suppliers by Stock Value (Millions SAR)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
        ),
        const SizedBox(height: 8),

        if (sortedVendors.isEmpty)
          const Text("No supplier data available", style: TextStyle(fontSize: 11, color: Colors.grey))
        else ...[
          ...displayedVendors.asMap().entries.map((entry) {
            int idx = entry.key;
            var vendorEntry = entry.value;
            String vendorName = vendorEntry.key;
            double val = vendorEntry.value;
            double valM = val / 1000000;
            double p = totalVendorVal > 0 ? (val / totalVendorVal) : 0.0;
            int pInt = (p * 100).round();
            Color col = kChartPalette[idx % kChartPalette.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: col.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${idx + 1}",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 180,
                            child: Text(
                              vendorName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF33333D)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${valM.toStringAsFixed(1)}M SAR ($pInt%)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: col),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: p.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(col),
                  ),
                ],
              ),
            );
          }),

          if (_supplierDisplayLimit < sortedVendors.length) ...[
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _supplierDisplayLimit += 10;
                  });
                },
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: Text("Show More (+10) [${sortedVendors.length - _supplierDisplayLimit} remaining]"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF303489),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTopItemsContent(List<Map<String, dynamic>> items) {
    Set<String> branches = {};
    Set<String> segments = {};
    for (var item in items) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.isNotEmpty && !loc.toLowerCase().contains('transit') && !loc.toLowerCase().contains('tramsit')) {
        branches.add(loc);
      }
      String seg = item['segment']?.toString().trim() ?? '';
      if (seg.isNotEmpty) segments.add(seg);
    }
    final sortedBranches = branches.toList()..sort(sortStockLocationOrder);
    final List<String> availableBranches = ['All', ...sortedBranches];
    final List<String> availableSegments = ['All', ...segments.toList()..sort()];

    final filteredItems = items.where((item) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) return false;

      String seg = item['segment']?.toString().trim() ?? '';
      bool matchesBranch = _selectedItemBranchFilter == 'All' || loc == _selectedItemBranchFilter;
      bool matchesSeg = _selectedItemSegmentFilter == null || _selectedItemSegmentFilter == 'All' || seg == _selectedItemSegmentFilter;

      return matchesBranch && matchesSeg;
    }).toList();

    final sortedItems = List<Map<String, dynamic>>.from(filteredItems)
      ..sort((a, b) => ((b['stock_value'] as num?)?.toDouble() ?? 0.0).compareTo((a['stock_value'] as num?)?.toDouble() ?? 0.0));

    double totalItemVal = sortedItems.fold<double>(0.0, (s, e) => s + ((e['stock_value'] as num?)?.toDouble() ?? 0.0));
    double totalM = totalItemVal / 1000000;

    final displayedItems = sortedItems.take(_itemDisplayLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF303489), Color(0xFF8045DD)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _kpiBox("Items", "${sortedItems.length}"),
              _kpiBox("Stock Value", "${totalM.toStringAsFixed(1)}M SAR"),
              _kpiBox("Showing", "${displayedItems.length} / ${sortedItems.length}"),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (availableBranches.length > 1) ...[
          const Text(
            "Filter by Branch:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...availableBranches.map((br) {
                  final isSelected = br == _selectedItemBranchFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        br == 'All' ? 'All Branches' : br,
                        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF33333D)),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF303489),
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedItemBranchFilter = br;
                            _itemDisplayLimit = 10;
                          });
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (availableSegments.length > 1) ...[
          const Text(
            "Filter by Segment:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...availableSegments.map((seg) {
                  final isSelected = (_selectedItemSegmentFilter ?? 'All') == seg;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        seg == 'All' ? 'All Segments' : seg,
                        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF33333D)),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8045DD),
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedItemSegmentFilter = seg;
                            _itemDisplayLimit = 10;
                          });
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        const Text(
          "Top Stock Items by Value (Millions SAR)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
        ),
        const SizedBox(height: 8),

        if (sortedItems.isEmpty)
          const Text("No item data available", style: TextStyle(fontSize: 11, color: Colors.grey))
        else ...[
          ...displayedItems.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            String materialName = item['material']?.toString().trim() ?? '';
            if (materialName.isEmpty) {
              materialName = item['material_description']?.toString().trim() ?? "${item['plant'] ?? ''} - ${item['division'] ?? 'Item'}";
            }
            if (materialName.trim().isEmpty) materialName = "Item #${idx + 1}";
            double val = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
            double valM = val / 1000000;
            double p = totalItemVal > 0 ? (val / totalItemVal) : 0.0;
            int pInt = (p * 100).round();
            Color col = kChartPalette[idx % kChartPalette.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: col.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${idx + 1}",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 180,
                            child: Text(
                              materialName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF33333D)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${valM.toStringAsFixed(1)}M SAR ($pInt%)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: col),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Branch: ${item['location'] ?? 'N/A'} | Segment: ${item['segment'] ?? 'N/A'} | Vendor: ${item['vendor'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: p.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(col),
                  ),
                ],
              ),
            );
          }),

          if (_itemDisplayLimit < sortedItems.length) ...[
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _itemDisplayLimit += 10;
                  });
                },
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: Text("Show More (+10) [${sortedItems.length - _itemDisplayLimit} remaining]"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF303489),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildExpiryAnalysisContent(List<Map<String, dynamic>> items) {
    Set<String> branches = {};
    Set<String> segments = {};
    for (var item in items) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.isNotEmpty && !loc.toLowerCase().contains('transit') && !loc.toLowerCase().contains('tramsit')) {
        branches.add(loc);
      }
      String seg = item['segment']?.toString().trim() ?? '';
      if (seg.isNotEmpty) segments.add(seg);
    }
    final sortedBranches = branches.toList()..sort(sortStockLocationOrder);
    final List<String> availableBranches = ['All', ...sortedBranches];
    final List<String> availableSegments = ['All', ...segments.toList()..sort()];

    final filteredItems = items.where((item) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) return false;

      String seg = item['segment']?.toString().trim() ?? '';
      bool matchesBranch = _selectedExpiryBranchFilter == 'All' || loc == _selectedExpiryBranchFilter;
      bool matchesSeg = _selectedExpirySegmentFilter == null || _selectedExpirySegmentFilter == 'All' || seg == _selectedExpirySegmentFilter;

      return matchesBranch && matchesSeg;
    }).toList();

    double totalStockVal = filteredItems.fold<double>(0.0, (s, e) => s + ((e['stock_value'] as num?)?.toDouble() ?? 0.0));
    double totalValM = totalStockVal / 1000000;

    Map<String, double> expiryCategoryVals = {};
    for (var item in filteredItems) {
      String cat = item['expire_category']?.toString().trim() ?? 'Salable';
      if (cat.isEmpty) cat = 'Salable';
      double val = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
      if (val > 0) {
        expiryCategoryVals[cat] = (expiryCategoryVals[cat] ?? 0.0) + val;
      }
    }
    final sortedCategories = expiryCategoryVals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Categories = sortedCategories.take(3).toList();

    String activeCategory = (_selectedExpiryCategory ?? top3Categories.firstOrNull?.key ?? 'Near Expire').trim().toLowerCase();

    Set<String> allMonths = {};
    Map<String, double> monthlyVals = {};

    for (var item in filteredItems) {
      String cat = item['expire_category']?.toString().trim().toLowerCase() ?? '';
      if (cat.isEmpty) cat = 'salable';

      if (activeCategory.contains('near')) {
        if (!cat.contains('near')) continue;
      } else if (activeCategory.contains('salable')) {
        if (!cat.contains('salable')) continue;
      } else {
        if (!cat.contains(activeCategory)) continue;
      }

      String expDate = item['expiry_date']?.toString().trim() ?? '';
      String monthKey = 'Unknown';
      if (expDate.length >= 7) {
        String yearStr = expDate.substring(0, 4);
        int? year = int.tryParse(yearStr);
        if (year == null || year < 2023 || year > 2040) continue;

        int? month = int.tryParse(expDate.substring(5, 7));
        if (month != null && month >= 1 && month <= 12) {
          monthKey = expDate.substring(0, 7);
        }
      }
      if (monthKey == 'Unknown') continue;

      double val = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
      if (val <= 0) continue;

      allMonths.add(monthKey);
      monthlyVals[monthKey] = (monthlyVals[monthKey] ?? 0.0) + val;
    }

    final sortedMonths = allMonths.where((m) => (monthlyVals[m] ?? 0.0) > 0).toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF303489), Color(0xFF8045DD)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _kpiBox("Total Stock", "${totalValM.toStringAsFixed(1)}M SAR"),
              _kpiBox("Categories", "${sortedCategories.length}"),
              _kpiBox("Months", "${sortedMonths.length}"),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (availableBranches.length > 1) ...[
          const Text(
            "Filter by Branch:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...availableBranches.map((br) {
                  final isSelected = br == _selectedExpiryBranchFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        br == 'All' ? 'All Branches' : br,
                        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF33333D)),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF303489),
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedExpiryBranchFilter = br;
                          });
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (availableSegments.length > 1) ...[
          const Text(
            "Filter by Segment:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...availableSegments.map((seg) {
                  final isSelected = (_selectedExpirySegmentFilter ?? 'All') == seg;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        seg == 'All' ? 'All Segments' : seg,
                        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF33333D)),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8045DD),
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedExpirySegmentFilter = seg;
                          });
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        const Text(
          "Stock Value & Percentage per Expiry Category (Click any ring to view trend)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
        ),
        const SizedBox(height: 10),
        if (top3Categories.isEmpty)
          const Text("No expiry category data", style: TextStyle(fontSize: 11, color: Colors.grey))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [
                ...top3Categories.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var catEntry = entry.value;
                  String catName = catEntry.key;
                  double val = catEntry.value;
                  double valM = val / 1000000;
                  double ratio = totalStockVal > 0 ? (val / totalStockVal) : 0.0;
                  int ratioInt = (ratio * 100).round();
                  Color col = kChartPalette[idx % kChartPalette.length];

                  String currentActive = (_selectedExpiryCategory ?? top3Categories.first.key).trim().toLowerCase();
                  bool isSel = currentActive.contains(catName.toLowerCase()) || (currentActive.contains('near') && catName.toLowerCase().contains('near'));

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedExpiryCategory = catName;
                          _selectedExpiryMonth = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? col.withValues(alpha: 0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? col : Colors.grey.shade200, width: isSel ? 2.0 : 1.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(col),
                                  ),
                                  Text(
                                    "$ratioInt%",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              catName.isEmpty ? 'Salable' : catName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF33333D)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${valM.toStringAsFixed(1)}M SAR",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 16),
              ],
            ),
          ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Stock Trends for \"${_selectedExpiryCategory ?? top3Categories.firstOrNull?.key ?? 'Near Expire'}\" by Month",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
            ),
            if (_selectedExpiryMonth != null)
              InkWell(
                onTap: () => setState(() => _selectedExpiryMonth = null),
                child: const Text("Clear Selection", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (sortedMonths.isEmpty)
          const Text("No monthly trend data for this category", style: TextStyle(fontSize: 11, color: Colors.grey))
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 200,
              width: math.max(600.0, sortedMonths.length * 90.0),
              child: CustomPaint(
                size: Size(math.max(600.0, sortedMonths.length * 90.0), 200),
                painter: ExpiryMonthLineChartPainter(sortedMonths, monthlyVals, _selectedExpiryMonth, const Color(0xFFE65100)),
              ),
            ),
          ),
          if (_selectedExpiryMonth != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Month: $_selectedExpiryMonth",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF303489)),
                  ),
                  Text(
                    "${_selectedExpiryCategory ?? 'Category'}: ${((monthlyVals[_selectedExpiryMonth!] ?? 0.0) / 1000000).toStringAsFixed(1)}M SAR",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFE65100)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildInsuranceLimitsContent(List<Map<String, dynamic>> items) {
    Set<String> storages = {};
    for (var item in items) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) continue;

      String st = item['storage_condition']?.toString().trim() ?? 'Dry';
      if (st.isEmpty || st.toUpperCase() == 'NA' || st.toUpperCase() == 'N/A') continue;
      storages.add(st);
    }
    final List<String> availableStorages = ['All', ...storages.toList()..sort()];

    final filteredItems = items.where((item) {
      String loc = item['location']?.toString().trim() ?? '';
      if (loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) return false;

      String st = item['storage_condition']?.toString().trim() ?? 'Dry';
      if (st.isEmpty) st = 'Dry';
      if (st.toUpperCase() == 'NA' || st.toUpperCase() == 'N/A') return false;

      bool matchesSt = _selectedInsuranceStorageFilter == 'All' || st == _selectedInsuranceStorageFilter;
      return matchesSt;
    }).toList();

    Map<String, double> branchStock = {};
    Map<String, double> branchInsur = {};

    for (var item in filteredItems) {
      String loc = item['location']?.toString().trim() ?? 'Unknown Branch';
      if (loc.isEmpty || loc.toLowerCase().contains('transit') || loc.toLowerCase().contains('tramsit')) continue;

      double stockVal = (item['stock_value'] as num?)?.toDouble() ?? 0.0;
      double insurVal = (item['insurance_value'] as num?)?.toDouble() ?? 0.0;

      branchStock[loc] = (branchStock[loc] ?? 0.0) + stockVal;
      branchInsur[loc] = (branchInsur[loc] ?? 0.0) + insurVal;
    }

    final sortedBranches = branchStock.keys.toList()..sort(sortStockLocationOrder);

    double totalStock = filteredItems.fold<double>(0.0, (s, e) => s + ((e['stock_value'] as num?)?.toDouble() ?? 0.0));
    double totalInsur = filteredItems.fold<double>(0.0, (s, e) => s + ((e['insurance_value'] as num?)?.toDouble() ?? 0.0));
    double overallRatio = totalInsur > 0 ? (totalStock / totalInsur) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF303489), Color(0xFF8045DD)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _kpiBox("Total Stock", "${(totalStock / 1000000).toStringAsFixed(1)}M SAR"),
              _kpiBox("Total Insurance", "${(totalInsur / 1000000).toStringAsFixed(1)}M SAR"),
              _kpiBox("Stock / Limit", "${overallRatio.toStringAsFixed(1)}%"),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (availableStorages.length > 1) ...[
          const Text(
            "Filter by Storage Condition:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF303489)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableStorages.map((st) {
                final isSelected = st == _selectedInsuranceStorageFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(
                      st == 'All' ? 'All Storage' : st,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF33333D),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8045DD),
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedInsuranceStorageFilter = st;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        const Text(
          "Stock Value vs Insurance Limit per Branch (Ring Progress)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF303489)),
        ),
        const SizedBox(height: 8),

        if (sortedBranches.isEmpty)
          const Text("No branch insurance data available", style: TextStyle(fontSize: 11, color: Colors.grey))
        else
          ...sortedBranches.asMap().entries.map((entry) {
            String branchName = entry.value;
            double sVal = branchStock[branchName] ?? 0.0;
            double iVal = branchInsur[branchName] ?? 0.0;
            double sM = sVal / 1000000;
            double iM = iVal / 1000000;
            double ratio = iVal > 0 ? (sVal / iVal) * 100 : 0.0;
            int ratioInt = ratio.round();

            Color col = const Color(0xFF00BFA5); // Green (0 - 75)
            if (ratioInt > 99) {
              col = Colors.redAccent; // Red (> 99)
            } else if (ratioInt >= 90) {
              col = Colors.orange; // Orange (90 - 99)
            } else if (ratioInt >= 75) {
              col = Colors.amber.shade800; // Yellow (75 - 90)
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (iVal > 0 ? (sVal / iVal).clamp(0.0, 1.0) : 0.0),
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(col),
                        ),
                        Text(
                          "$ratioInt%",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branchName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF33333D)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Stock: ${sM.toStringAsFixed(1)}M SAR", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2659E4))),
                            Text("Insurance: ${iM.toStringAsFixed(1)}M SAR", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8045DD))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildOtherReportsContent(List<Map<String, dynamic>> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Report details for $type", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF33333D))),
        const SizedBox(height: 8),
        ...items.take(4).map((i) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(i['vendor'] ?? i['plant'] ?? 'Record', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text("${(((i['stock_value'] as num?)?.toDouble() ?? 0.0) / 1000000).toStringAsFixed(1)}M SAR", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF8045DD))),
                ],
              ),
            )),
      ],
    );
  }
}

class StockPieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final List<Color> palette;
  final String? selectedKey;

  StockPieChartPainter(this.data, this.palette, this.selectedKey);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double total = data.fold(0.0, (sum, e) => sum + e.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final color = palette[(i + 2) % palette.length];
      final isSelected = entry.key == selectedKey;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      if (isSelected) {
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = 3.0;
        canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);
      }

      startAngle += sweepAngle;
    }

    final innerRadius = radius * 0.55;
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF9FBFB);
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant StockPieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedKey != selectedKey;
  }
}

class ExpiryMonthLineChartPainter extends CustomPainter {
  final List<String> months;
  final Map<String, double> monthlyVals;
  final String? selectedMonth;
  final Color lineColor;

  ExpiryMonthLineChartPainter(this.months, this.monthlyVals, this.selectedMonth, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double maxVal = 1.0;
    for (var m in months) {
      double n = (monthlyVals[m] ?? 0.0) / 1000000;
      if (n > maxVal) maxVal = n;
    }

    final double paddingX = 45.0;
    final double paddingY = 30.0;
    final double usableWidth = size.width - (paddingX * 2);
    final double usableHeight = size.height - (paddingY * 2) - 15;

    for (int i = 0; i <= 4; i++) {
      double y = paddingY + (usableHeight / 4) * i;
      canvas.drawLine(Offset(paddingX - 10, y), Offset(size.width - paddingX + 10, y), paintGrid);
      
      double labelVal = maxVal * (1.0 - (i / 4));
      final textSpan = TextSpan(
        text: "${labelVal.toStringAsFixed(1)}M",
        style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - (textPainter.height / 2)));
    }

    Path pathLine = Path();
    List<Offset> points = [];

    for (int i = 0; i < months.length; i++) {
      String m = months[i];
      double val = (monthlyVals[m] ?? 0.0) / 1000000;

      double x = paddingX + (months.length > 1 ? (i / (months.length - 1)) * usableWidth : usableWidth / 2);
      double y = paddingY + usableHeight - ((val / maxVal) * usableHeight);

      points.add(Offset(x, y));

      if (i == 0) {
        pathLine.moveTo(x, y);
      } else {
        pathLine.lineTo(x, y);
      }
    }

    canvas.drawPath(pathLine, paintLine);

    for (int i = 0; i < months.length; i++) {
      bool isSelected = months[i] == selectedMonth;

      canvas.drawCircle(points[i], isSelected ? 8 : 5, Paint()..color = lineColor..style = PaintingStyle.fill);
      canvas.drawCircle(points[i], isSelected ? 4 : 2, Paint()..color = Colors.white..style = PaintingStyle.fill);

      final textSpan = TextSpan(
        text: months[i],
        style: TextStyle(
          color: isSelected ? const Color(0xFF303489) : const Color(0xFF33333D),
          fontSize: isSelected ? 11 : 10,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - (textPainter.width / 2), size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant ExpiryMonthLineChartPainter oldDelegate) {
    return oldDelegate.months != months || oldDelegate.selectedMonth != selectedMonth || oldDelegate.lineColor != lineColor;
  }
}
