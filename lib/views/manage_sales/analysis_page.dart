import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String _selectedPeriod = 'Week';
  String? _selectedWeek;
  String? _selectedMonth;
  String? _selectedYear;

  final List<String> _periods = ['Week', 'Month', 'Year'];
  final List<String> _weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
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

  // Sample data for the chart
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
    _selectedWeek = _weeks[0];
    _selectedMonth = 'May';
    _selectedYear = '2025';
  }

  String get _displayTitle {
    if (_selectedPeriod == 'Week') {
      return 'Total Sales ($_selectedWeek, $_selectedMonth $_selectedYear)';
    } else if (_selectedPeriod == 'Month') {
      return 'Total Sales ($_selectedMonth $_selectedYear)';
    } else {
      return 'Total Sales ($_selectedYear)';
    }
  }

  // Sample ranking data
  final List<Map<String, dynamic>> _rankings = [
    {
      'id': 'FE001',
      'name': 'Tasik Chini',
      'sales': 200.00,
      'avatar': Icons.person,
    },
    {
      'id': 'FE005',
      'name': 'Sri Kuantan',
      'sales': 150.00,
      'avatar': Icons.person,
    },
    {
      'id': 'FE009',
      'name': 'Taman Perdana',
      'sales': 100.00,
      'avatar': Icons.person,
    },
    {
      'id': 'FE006',
      'name': 'Alor Setar',
      'sales': 50.00,
      'avatar': Icons.person,
    },
    {'id': 'FE002', 'name': 'Gombak', 'sales': 20.00, 'avatar': Icons.person},
  ];

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
              // Title
              Text(
                _displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Period Filter (Week/Month/Year)
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
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Filters based on selected period
              _buildDynamicFilters(),
              const SizedBox(height: 20),

              // Bar Chart Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Chart
                    SizedBox(height: 250, child: _buildBarChart()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sales Ranking Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Sales Ranking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'My Rank : 20',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ranking List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header Row
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Franchisee',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Sales (RM)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ranking Items
                    ..._rankings.asMap().entries.map((entry) {
                      final index = entry.key;
                      final franchisee = entry.value;
                      return _buildRankingItem(
                        rank: index + 1,
                        id: franchisee['id'],
                        name: franchisee['name'],
                        sales: franchisee['sales'],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
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
        hint: Text(label),
        items: [
          DropdownMenuItem(value: 'All Time', child: Text(label)),
          DropdownMenuItem(value: 'Sales', child: Text(label)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDynamicFilters() {
    if (_selectedPeriod == 'Week') {
      // Show Week, Month, and Year dropdowns
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Week',
                  value: _selectedWeek!,
                  items: _weeks,
                  onChanged: (value) {
                    setState(() {
                      _selectedWeek = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Month',
                  value: _selectedMonth!,
                  items: _months,
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            label: 'Year',
            value: _selectedYear!,
            items: _years,
            onChanged: (value) {
              setState(() {
                _selectedYear = value!;
              });
            },
          ),
        ],
      );
    } else if (_selectedPeriod == 'Month') {
      // Show Month and Year dropdowns
      return Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              label: 'Month',
              value: _selectedMonth!,
              items: _months,
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              label: 'Year',
              value: _selectedYear!,
              items: _years,
              onChanged: (value) {
                setState(() {
                  _selectedYear = value!;
                });
              },
            ),
          ),
        ],
      );
    } else {
      // Show only Year dropdown
      return _buildFilterDropdown(
        label: 'Year',
        value: _selectedYear!,
        items: _years,
        onChanged: (value) {
          setState(() {
            _selectedYear = value!;
          });
        },
      );
    }
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

  Widget _buildBarChart() {
    final maxValue = _chartData
        .map((e) => e['value'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _chartData.map((data) {
        final value = data['value'] as int;
        final height = (value / maxValue) * 200;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Value label above bar
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
            const SizedBox(height: 4),
            // Bar
            Container(
              width: 35,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.chartRed,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Day label
            Text(
              data['day'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
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
          // Rank Badge
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
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 24),
          ),
          const SizedBox(width: 12),
          // Name and ID
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
          // Sales
          Text(
            sales.toStringAsFixed(2),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
