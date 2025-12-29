// lib/pages/admin/admin_sales_insights.dart
import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/providers/report_controller.dart';
import 'package:myakieburger/widgets/custom_loading_dialog.dart';
import 'package:intl/intl.dart';

class AdminSalesInsights extends StatefulWidget {
  const AdminSalesInsights({super.key});

  @override
  State<AdminSalesInsights> createState() => _AdminSalesInsightsState();
}

class _AdminSalesInsightsState extends State<AdminSalesInsights> {
  final ReportController _reportController = ReportController();

  String _selectedPeriod = 'Month';
  String? _selectedMonth;
  String? _selectedYear;
  int? _selectedWeek;

  bool _isLoading = false;
  bool _isInitialLoad = true;

  double _totalSales = 0.0;
  int _totalOrders = 0;
  int _totalMealsSold = 0;
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _topFranchisees = [];

  final List<String> _periods = ['Week', 'Month', 'Year'];
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
  final List<String> _years = ['2023', '2024', '2025', '2026'];

  final ScrollController _chartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
    _selectedYear = DateTime.now().year.toString();
    _selectedWeek = _getCurrentWeekOfMonth();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  int _getCurrentWeekOfMonth() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysSinceFirstDay = now.difference(firstDayOfMonth).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }

  Future<void> _initializeData() async {
    if (mounted) {
      CustomLoadingDialog.show(context, message: 'Loading Sales Data...');
    }

    await _fetchSalesData();

    if (mounted) {
      CustomLoadingDialog.hide(context);
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _fetchSalesData() async {
    setState(() => _isLoading = true);

    try {
      final allReports = await _reportController.getAllReports();

      if (_selectedPeriod == 'Week') {
        await _processWeeklySales(allReports);
      } else if (_selectedPeriod == 'Month') {
        await _processMonthlySales(allReports);
      } else {
        await _processYearlySales(allReports);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error fetching sales data: $e');
      setState(() => _isLoading = false);
    }
  }

  // 🔹 FIXED: Week shows all 7 days of the selected week
  Future<void> _processWeeklySales(List<Map<String, dynamic>> reports) async {
    final monthIndex = _months.indexOf(_selectedMonth!) + 1;
    final year = int.parse(_selectedYear!);

    // Get the date range for the selected week
    final firstDayOfMonth = DateTime(year, monthIndex, 1);
    final startDate = firstDayOfMonth.add(
      Duration(days: (_selectedWeek! - 1) * 7),
    );
    final endDate = startDate.add(const Duration(days: 6));

    double totalSales = 0.0;
    int totalOrders = 0;
    int totalMealsSold = 0;
    Map<String, double> franchiseeSales = {};
    List<Map<String, dynamic>> dailyData = [];

    // Initialize daily data for 7 days
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      dailyData.add({
        'label': DateFormat('E').format(date), // Mon, Tue, Wed, etc.
        'fullDate': DateFormat('dd/MM/yyyy').format(date),
        'value': 0.0,
      });
    }

    // Process reports
    for (var report in reports) {
      final reportDateStr = report['report_date'] as String?;
      if (reportDateStr == null) continue;

      try {
        final reportDate = DateFormat('dd/MM/yyyy').parse(reportDateStr);

        if (reportDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            reportDate.isBefore(endDate.add(const Duration(days: 1)))) {
          final sales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
          final orders = report['total_orders'] as int? ?? 0;
          final meals = report['total_meals_sold'] as int? ?? 0;
          final franchiseeName =
              report['franchisee_name'] as String? ?? 'Unknown';

          totalSales += sales;
          totalOrders += orders;
          totalMealsSold += meals;

          franchiseeSales[franchiseeName] =
              (franchiseeSales[franchiseeName] ?? 0.0) + sales;

          // Add to daily data
          final dayIndex = reportDate.difference(startDate).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            dailyData[dayIndex]['value'] =
                (dailyData[dayIndex]['value'] as double) + sales;
          }
        }
      } catch (e) {
        print('Error parsing date: $reportDateStr - $e');
      }
    }

    // Sort franchisees by sales
    final sortedFranchisees = franchiseeSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _totalSales = totalSales;
      _totalOrders = totalOrders;
      _totalMealsSold = totalMealsSold;
      _chartData = dailyData;
      _topFranchisees = sortedFranchisees
          .take(5)
          .map((e) => {'name': e.key, 'sales': e.value})
          .toList();
    });
  }

  // 🔹 FIXED: Month shows all 12 months of the selected year
  Future<void> _processMonthlySales(List<Map<String, dynamic>> reports) async {
    final year = int.parse(_selectedYear!);

    double totalSales = 0.0;
    int totalOrders = 0;
    int totalMealsSold = 0;
    Map<String, double> franchiseeSales = {};
    Map<int, double> monthlySales = {};

    // Initialize all 12 months
    for (int i = 1; i <= 12; i++) {
      monthlySales[i] = 0.0;
    }

    for (var report in reports) {
      final reportDateStr = report['report_date'] as String?;
      if (reportDateStr == null) continue;

      try {
        final reportDate = DateFormat('dd/MM/yyyy').parse(reportDateStr);

        if (reportDate.year == year) {
          final sales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
          final orders = report['total_orders'] as int? ?? 0;
          final meals = report['total_meals_sold'] as int? ?? 0;
          final franchiseeName =
              report['franchisee_name'] as String? ?? 'Unknown';

          totalSales += sales;
          totalOrders += orders;
          totalMealsSold += meals;

          franchiseeSales[franchiseeName] =
              (franchiseeSales[franchiseeName] ?? 0.0) + sales;

          // Add to monthly data
          final monthIndex = reportDate.month;
          monthlySales[monthIndex] = (monthlySales[monthIndex] ?? 0.0) + sales;
        }
      } catch (e) {
        print('Error parsing date: $reportDateStr - $e');
      }
    }

    // Sort franchisees by sales
    final sortedFranchisees = franchiseeSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare chart data - all 12 months
    final chartData = monthlySales.entries
        .map(
          (e) => {
            'label': _months[e.key - 1].substring(0, 3), // Jan, Feb, etc.
            'value': e.value,
          },
        )
        .toList();

    setState(() {
      _totalSales = totalSales;
      _totalOrders = totalOrders;
      _totalMealsSold = totalMealsSold;
      _chartData = chartData;
      _topFranchisees = sortedFranchisees
          .take(5)
          .map((e) => {'name': e.key, 'sales': e.value})
          .toList();
    });
  }

  // 🔹 FIXED: Year shows all available years with sales
  Future<void> _processYearlySales(List<Map<String, dynamic>> reports) async {
    double totalSales = 0.0;
    int totalOrders = 0;
    int totalMealsSold = 0;
    Map<String, double> franchiseeSales = {};
    Map<String, double> yearlySales = {};

    // Initialize all years
    for (final year in _years) {
      yearlySales[year] = 0.0;
    }

    for (var report in reports) {
      final reportDateStr = report['report_date'] as String?;
      if (reportDateStr == null) continue;

      try {
        final reportDate = DateFormat('dd/MM/yyyy').parse(reportDateStr);
        final yearStr = reportDate.year.toString();

        // Only process if year is in our list
        if (_years.contains(yearStr)) {
          final sales = (report['total_sales'] as num?)?.toDouble() ?? 0.0;
          final orders = report['total_orders'] as int? ?? 0;
          final meals = report['total_meals_sold'] as int? ?? 0;
          final franchiseeName =
              report['franchisee_name'] as String? ?? 'Unknown';

          totalSales += sales;
          totalOrders += orders;
          totalMealsSold += meals;

          franchiseeSales[franchiseeName] =
              (franchiseeSales[franchiseeName] ?? 0.0) + sales;

          yearlySales[yearStr] = (yearlySales[yearStr] ?? 0.0) + sales;
        }
      } catch (e) {
        print('Error parsing date: $reportDateStr - $e');
      }
    }

    // Sort franchisees by sales
    final sortedFranchisees = franchiseeSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare chart data - all years
    final chartData = _years
        .map((year) => {'label': year, 'value': yearlySales[year] ?? 0.0})
        .toList();

    setState(() {
      _totalSales = totalSales;
      _totalOrders = totalOrders;
      _totalMealsSold = totalMealsSold;
      _chartData = chartData;
      _topFranchisees = sortedFranchisees
          .take(5)
          .map((e) => {'name': e.key, 'sales': e.value})
          .toList();
    });
  }

  String get _displayTitle {
    if (_selectedPeriod == 'Week') {
      return 'Week $_selectedWeek - $_selectedMonth $_selectedYear';
    } else if (_selectedPeriod == 'Month') {
      return 'Monthly Sales ($_selectedYear)';
    } else {
      return 'Yearly Sales Overview';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return Scaffold(
        backgroundColor: AppColors.admin,
        appBar: _buildAppBar(),
        body: const SizedBox(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.admin,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                _displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Summary Cards
              _buildSummaryCards(),
              const SizedBox(height: 20),

              // Period Filter
              _buildPeriodFilter(),
              const SizedBox(height: 12),

              // Dynamic Filters
              _buildDynamicFilters(),
              const SizedBox(height: 20),

              // Chart
              _buildChartContainer(),
              const SizedBox(height: 24),

              // Top Franchisees
              _buildTopFranchisees(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.admin,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Sales Insights',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Sales',
            'RM ${_totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
            AppColors.lightPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Orders',
            _totalOrders.toString(),
            Icons.shopping_cart,
            const Color(0xFF6C63FF),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    );
  }

  Widget _buildDynamicFilters() {
    if (_selectedPeriod == 'Week') {
      return Column(
        children: [
          _buildFilterDropdown(
            value: _selectedMonth!,
            items: _months,
            onChanged: (value) {
              setState(() => _selectedMonth = value!);
              _fetchSalesData();
            },
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            value: _selectedYear!,
            items: _years,
            onChanged: (value) {
              setState(() => _selectedYear = value!);
              _fetchSalesData();
            },
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            value: 'Week $_selectedWeek',
            items: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'],
            onChanged: (value) {
              setState(() => _selectedWeek = int.parse(value!.split(' ')[1]));
              _fetchSalesData();
            },
          ),
        ],
      );
    } else if (_selectedPeriod == 'Month') {
      return _buildFilterDropdown(
        value: _selectedYear!,
        items: _years,
        onChanged: (value) {
          setState(() => _selectedYear = value!);
          _fetchSalesData();
        },
      );
    } else {
      // Year - no filters needed
      return const SizedBox();
    }
  }

  Widget _buildFilterDropdown({
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

  Widget _buildChartContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 300,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.admin),
              )
            : _buildBarChart(),
      ),
    );
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

    final values = _chartData
        .map((e) => (e['value'] as num).toDouble())
        .toList();
    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SingleChildScrollView(
        controller: _chartScrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            SizedBox(
              width: _chartData.length * 50.0,
              height: 230,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      5,
                      (index) => Container(height: 1, color: Colors.grey[200]),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _chartData.map((data) {
                        final value = (data['value'] as num).toDouble();
                        final height = maxValue > 0
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
                                        AppColors.admin,
                                        AppColors.admin.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.admin.withOpacity(0.3),
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

  Widget _buildTopFranchisees() {
    if (_topFranchisees.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Franchisees',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topFranchisees.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final franchisee = _topFranchisees[index];
              final rank = index + 1;

              Color rankColor;
              if (rank == 1) {
                rankColor = const Color(0xFFFFD700); // Gold
              } else if (rank == 2) {
                rankColor = const Color(0xFFC0C0C0); // Silver
              } else if (rank == 3) {
                rankColor = const Color(0xFFCD7F32); // Bronze
              } else {
                rankColor = Colors.grey;
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                      ),
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
                    Expanded(
                      child: Text(
                        franchisee['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'RM ${(franchisee['sales'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.admin,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
