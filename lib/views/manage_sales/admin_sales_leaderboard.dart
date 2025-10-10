import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';

class AdminSalesLeaderboard extends StatefulWidget {
  const AdminSalesLeaderboard({super.key});

  @override
  State<AdminSalesLeaderboard> createState() => _AdminSalesLeaderboardState();
}

class _AdminSalesLeaderboardState extends State<AdminSalesLeaderboard> {
  String selectedPeriod = 'Weekly';

  final List<Map<String, dynamic>> leaderboardData = [
    {
      'rank': 1,
      'name': 'Akmal',
      'sales': 'RM 45,230',
      'image': 'assets/profile.png',
      'growth': '+12%',
    },
    {
      'rank': 2,
      'name': 'Ahmad',
      'sales': 'RM 42,100',
      'image': 'assets/profile.png',
      'growth': '+8%',
    },
    {
      'rank': 3,
      'name': 'Ammar',
      'sales': 'RM 38,950',
      'image': 'assets/profile.png',
      'growth': '+15%',
    },
    {
      'rank': 4,
      'name': 'You',
      'sales': 'RM 35,600',
      'image': 'assets/profile.png',
      'growth': '+10%',
    },
    {
      'rank': 5,
      'name': 'Ali',
      'sales': 'RM 32,450',
      'image': 'assets/profile.png',
      'growth': '+5%',
    },
    {
      'rank': 6,
      'name': 'Yusof',
      'sales': 'RM 28,300',
      'image': 'assets/profile.png',
      'growth': '+7%',
    },
    {
      'rank': 7,
      'name': 'Azlan',
      'sales': 'RM 25,800',
      'image': 'assets/profile.png',
      'growth': '+3%',
    },
  ];

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.lightPurple;
    }
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getRankColor(rank),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Sales Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Period Buttons
            Row(
              children: [
                Expanded(child: _buildPeriodButton('Weekly')),
                const SizedBox(width: 12),
                Expanded(child: _buildPeriodButton('All Time')),
              ],
            ),
            const SizedBox(height: 20),

            // Leaderboard List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaderboardData.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboardData[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900], // same for all
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildRankBadge(entry['rank']),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              entry['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry['sales'],
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry['growth'],
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.admin : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.lightPurple : Colors.grey.shade800,
          ),
        ),
        child: Center(
          child: Text(
            period,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
