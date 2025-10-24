import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/providers/meal_order_controller.dart';

class AdminAnalysisPage extends StatefulWidget {
  const AdminAnalysisPage({super.key});

  @override
  State<AdminAnalysisPage> createState() => _AdminAnalysisPageState();
}

class _AdminAnalysisPageState extends State<AdminAnalysisPage> {
  final MealOrderController _mealOrderController = MealOrderController();

  String _selectedPeriod = 'Month';
  String _selectedYear = '2025';
  double? _totalSales;
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

  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
  }

  Future<void> _fetchSalesData() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> chartPoints = [];
      double total = 0.0;

      if (_selectedPeriod == 'Month') {
        final year = int.parse(_selectedYear);
        for (int month = 1; month <= 12; month++) {
          final result = await _mealOrderController.getAllSalesByMonth(
            month,
            year,
          );
          final value = result['totalSales'] ?? 0.0;
          chartPoints.add({
            'label': _months[month - 1].substring(0, 3),
            'value': value,
          });
          total += value;
        }
      } else {
        for (final yearStr in _years) {
          final year = int.parse(yearStr);
          final result = await _mealOrderController.getAllSalesByYear(year);
          final value = result['totalSales'] ?? 0.0;
          chartPoints.add({'label': yearStr, 'value': value});
          total += value;
        }
      }

      setState(() {
        _totalSales = total;
        _chartData = chartPoints;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching admin sales: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sales Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.admin.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.lightPurple,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading analytics...',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Sales Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.admin,
                            AppColors.lightPurple.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.admin.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedPeriod == 'Month'
                                          ? _selectedYear
                                          : 'All Years',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _selectedPeriod == 'Month'
                                ? 'Total Monthly Sales'
                                : 'Total Yearly Sales',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _totalSales != null
                                ? 'RM ${_totalSales!.toStringAsFixed(2)}'
                                : 'No data',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Filters Section
                    const Text(
                      'Analysis Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Period Filter
                    _buildModernDropdown(
                      value: _selectedPeriod,
                      icon: Icons.filter_list,
                      items: _periods
                          .map(
                            (period) => DropdownMenuItem(
                              value: period,
                              child: Text('Filter by $period'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPeriod = value!);
                        _fetchSalesData();
                      },
                    ),
                    const SizedBox(height: 12),

                    // Year Filter (only for Month view)
                    if (_selectedPeriod == 'Month')
                      _buildModernDropdown(
                        value: _selectedYear,
                        icon: Icons.calendar_today,
                        items: _years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text('Year $y'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedYear = value!);
                          _fetchSalesData();
                        },
                      ),
                    const SizedBox(height: 28),

                    // Chart Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sales Breakdown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bar_chart,
                                color: AppColors.lightPurple,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_chartData.length} Data Points',
                                style: TextStyle(
                                  color: AppColors.lightPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chart Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lightPurple.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: _buildModernChart(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.admin.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.lightPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF2A2A2A),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.lightPurple,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChart() {
    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final maxValue = _chartData
        .map((e) => e['value'] as double)
        .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final value = data['value'] as double;
          final height = maxValue > 0 ? (value / maxValue) * 220 : 0.0;

          // Create gradient colors for variety
          final gradientStart = index % 2 == 0
              ? AppColors.admin
              : AppColors.lightPurple;
          final gradientEnd = index % 2 == 0
              ? AppColors.lightPurple
              : AppColors.admin;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}K'
                        : value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bar
                Container(
                  width: 40,
                  height: height > 10 ? height : 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientStart.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Label
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    data['label'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
