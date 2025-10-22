import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/theme/app_colors.dart';

class FranchiseeDetailsPage extends StatelessWidget {
  final String franchiseeId;

  const FranchiseeDetailsPage({super.key, required this.franchiseeId});

  Future<Map<String, dynamic>?> _fetchFranchiseeDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(franchiseeId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print("❌ Error fetching details: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.admin,
            AppColors.admin.withOpacity(0.8),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchFranchiseeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.lightPurple,
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.lightPurple,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No details available',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final createdAt = data['created_at'] != null
              ? DateTime.tryParse(data['created_at'])
              : null;

          return Stack(
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Profile section with glow effect
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightPurple.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.lightPurple.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: const AssetImage(
                            'assets/profile.png',
                          ),
                          backgroundColor: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Username with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppColors.white, AppColors.lightPurple],
                      ).createShader(bounds),
                      child: Text(
                        data['username'] ?? 'Unnamed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Stall name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lightPurple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        data['stall_name'] ?? 'No stall assigned',
                        style: TextStyle(
                          color: AppColors.lightPurple,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Details card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lightPurple.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightPurple.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailItem(
                            Icons.email_outlined,
                            'Email',
                            data['email'] ?? '-',
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            Icons.location_on_outlined,
                            'Region',
                            data['region'] ?? '-',
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            Icons.phone_outlined,
                            'Contact',
                            data['contact'] ?? '-',
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            Icons.calendar_today_outlined,
                            'Created At',
                            createdAt != null
                                ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                                : '-',
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            Icons.badge_outlined,
                            'Role',
                            data['role'] ?? '-',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Close button with gradient background
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lightPurple.withOpacity(0.3),
                        AppColors.admin.withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightPurple.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    iconSize: 24,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String title,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.lightPurple.withOpacity(0.3),
                  AppColors.lightPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.lightPurple, size: 20),
          ),
          const SizedBox(width: 12),

          // Title and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.lightPurple.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.lightPurple.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
