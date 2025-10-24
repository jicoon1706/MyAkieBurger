import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String _selectedPeriod = 'Month';
  String? _selectedMonth;
  String? _selectedYear;

  final MealOrderController _mealOrderController = MealOrderController();

  double? _totalSales; // holds fetched total sales
  bool _isLoading = false;

  final List<String> _periods = ['Month', 'Year'];
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<String> _years = ['2023', '2024', '2025'];

  // Sample data for chart
  final List<Map<String, dynamic>> _chartData = [
    {'day': 'M', 'value': 120},
    {'day': 'T', 'value': 180},
    {'day': 'W', 'value': 250},
    {'day': 'T', 'value': 280},
    {'day': 'F', 'value': 380},
    {'day': 'S', 'value': 300},
    {'day': 'S', 'value': 150},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = 'May';
    _selectedYear = '2025';
    _fetchSalesData(); // 🟢 load initial sales
  }

  String get _displayTitle {
    if (_selectedPeriod == 'Month') {
      return 'Monthly Sales ($_selectedYear)';
    } else {
      return 'Yearly Sales Overview';
    }
  }

  final List<Map<String, dynamic>> _rankings = [
    {'id': 'FE001', 'name': 'Tasik Chini', 'sales': 200.00},
    {'id': 'FE005', 'name': 'Sri Kuantan', 'sales': 150.00},
    {'id': 'FE009', 'name': 'Taman Perdana', 'sales': 100.00},
    {'id': 'FE006', 'name': 'Alor Setar', 'sales': 50.00},
    {'id': 'FE002', 'name': 'Gombak', 'sales': 20.00},
  ];

  Future<void> _fetchSalesData() async {
    setState(() => _isLoading = true);

    try {
      final franchiseeId = await getLoggedInUserId();
      if (franchiseeId == null) {
        print('❌ No logged-in user found.');
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic> result = {};
      List<Map<String, dynamic>> chartPoints = [];

      if (_selectedPeriod == 'Month') {
        final yearNumber = int.parse(_selectedYear!);
        // Fetch sales per month for the selected year
        for (int month = 1; month <= 12; month++) {
          final data = await _mealOrderController.getSalesByMonth(
            franchiseeId,
            month,
            yearNumber,
          );
          chartPoints.add({
            'label': _months[month - 1].substring(0, 3), // Jan, Feb, ...
            'value': data['totalSales'] ?? 0.0,
          });
        }
        result['totalSales'] = chartPoints.fold(
          0.0,
          (sum, e) => sum + e['value'],
        );
      } else if (_selectedPeriod == 'Year') {
        // Get all possible years with sales
        chartPoints = [];
        for (final y in _years) {
          final data = await _mealOrderController.getSalesByYear(
            franchiseeId,
            int.parse(y),
          );
          final sales = data['totalSales'] ?? 0.0;
          if (sales > 0) {
            chartPoints.add({'label': y, 'value': sales});
          }
        }
        result['totalSales'] = chartPoints.fold(
          0.0,
          (sum, e) => sum + e['value'],
        );
      }

      setState(() {
        _totalSales = result['totalSales'];
        _chartData
          ..clear()
          ..addAll(chartPoints);
        _isLoading = false;
      });

      print('✅ Total Sales: RM ${_totalSales!.toStringAsFixed(2)}');
    } catch (e) {
      print('❌ Error fetching sales data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analysis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Loading / Total Sales
              // if (_isLoading)
              //   const Center(
              //     child: CircularProgressIndicator(color: Colors.white),
              //   )
              // else if (_totalSales != null)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              //     child: Text(
              //       'RM ${_totalSales!.toStringAsFixed(2)}',
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontSize: 20,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
              const SizedBox(height: 16),

              // Period Filter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _periods.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text('Filter by $period'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                    _fetchSalesData();
                  },
                ),
              ),

              const SizedBox(height: 12),

              _buildDynamicFilters(),
              const SizedBox(height: 20),

              // Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(height: 300, child: _buildBarChart()),
              ),

              const SizedBox(height: 24),

              // Ranking Section
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     const Text(
              //       'Sales Ranking',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 18,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //     TextButton(
              //       onPressed: () {
              //         Navigator.pushNamed(
              //           context,
              //           Routes.franchiseesSalesLeaderboard,
              //         );
              //       },
              //       child: const Text(
              //         'View All',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 14,
              //           decoration: TextDecoration.underline,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 16),

              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Column(
              //     children: _rankings
              //         .asMap()
              //         .entries
              //         .map(
              //           (entry) => _buildRankingItem(
              //             rank: entry.key + 1,
              //             id: entry.value['id'],
              //             name: entry.value['name'],
              //             sales: entry.value['sales'],
              //           ),
              //         )
              //         .toList(),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFilters() {
    if (_selectedPeriod == 'Month') {
      return _buildFilterDropdown(
        label: 'Year',
        value: _selectedYear!,
        items: _years,
        onChanged: (value) {
          setState(() => _selectedYear = value!);
          _fetchSalesData(); // refresh data
        },
      );
    } else {
      // Period == Year
      return const SizedBox(); // no filters for year mode
    }
  }

  // Add this as a class member at the top of _AnalysisPageState
  final ScrollController _chartScrollController = ScrollController();

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  Widget _buildBarChart() {
    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final List<double> values = _chartData
        .map((e) => (e['value'] as num).toDouble())
        .toList();
    final double maxValue = values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0), // prevent overflow
      child: SingleChildScrollView(
        controller: _chartScrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Chart area
            SizedBox(
              width: _chartData.length * 50.0,
              height: 230,
              child: Stack(
                children: [
                  // Horizontal grid lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      5,
                      (index) => Container(height: 1, color: Colors.grey[200]),
                    ),
                  ),

                  // Bars
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _chartData.asMap().entries.map((entry) {
                        final data = entry.value;
                        final double value = (data['value'] as num).toDouble();
                        final double height = maxValue > 0
                            ? (value / maxValue) * 185.0
                            : 0.0;

                        return SizedBox(
                          width: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (value > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      value >= 1000
                                          ? '${(value / 1000).toStringAsFixed(1)}K'
                                          : value.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 34,
                                  height: height,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppColors.chartRed,
                                        AppColors.chartRed.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.chartRed.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // X-axis separator and labels
            SizedBox(
              width: _chartData.length * 50.0,
              child: Column(
                children: [
                  Container(height: 2, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _chartData.map((data) {
                      final label = data['label']?.toString() ?? '';
                      return SizedBox(
                        width: 50,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String id,
    required String name,
    required double sales,
  }) {
    Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.chartRed;
    } else if (rank == 2) {
      rankColor = AppColors.chartRed.withOpacity(0.8);
    } else if (rank == 3) {
      rankColor = AppColors.chartRed.withOpacity(0.6);
    } else {
      rankColor = AppColors.chartRed.withOpacity(0.4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            sales.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
