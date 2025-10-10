import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';

class FranchiseesSalesLeaderboard extends StatefulWidget {
  const FranchiseesSalesLeaderboard({super.key});

  @override
  State<FranchiseesSalesLeaderboard> createState() =>
      _FranchiseesSalesLeaderboardState();
}

class _FranchiseesSalesLeaderboardState
    extends State<FranchiseesSalesLeaderboard> {
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
      'isCurrentUser': true,
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
    {
      'rank': 8,
      'name': 'Ali',
      'sales': 'RM 32,450',
      'image': 'assets/profile.png',
      'growth': '+5%',
    },
    {
      'rank': 9,
      'name': 'Yusof',
      'sales': 'RM 28,300',
      'image': 'assets/profile.png',
      'growth': '+7%',
    },
    {
      'rank': 10,
      'name': 'Azlan',
      'sales': 'RM 25,800',
      'image': 'assets/profile.png',
      'growth': '+3%',
    },
  ];

  Color _getRankColor(int rank) {
    if (rank == 1) return AppColors.chartRed;
    if (rank == 2) return AppColors.chartRed.withOpacity(0.8);
    if (rank == 3) return AppColors.chartRed.withOpacity(0.6);
    return AppColors.chartRed.withOpacity(0.4);
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
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserRank = leaderboardData.firstWhere(
      (entry) => entry['isCurrentUser'] == true,
    )['rank'];
    final totalUsers = leaderboardData.length;
    final percentile = ((totalUsers - currentUserRank) / totalUsers * 100)
        .round();

    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
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

            // Current User Highlight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.chartRed,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '#$currentUserRank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You are doing better than',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percentile% of franchisees',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Leaderboard List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaderboardData.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboardData[index];
                    final isCurrentUser = entry['isCurrentUser'] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppColors.chartRed.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentUser
                              ? AppColors.chartRed
                              : Colors.grey.shade300,
                          width: 1.2,
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
                                Row(
                                  children: [
                                    Text(
                                      entry['name'],
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? AppColors.chartRed
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.chartRed,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'YOU',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry['sales'],
                                  style: const TextStyle(
                                    color: Colors.black54,
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
          color: isSelected
              ? Colors.white
              : AppColors.chartRed.withOpacity(0.4),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.chartRed,
          ),
        ),
        child: Center(
          child: Text(
            period,
            style: TextStyle(
              color: isSelected ? AppColors.primaryRed : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
