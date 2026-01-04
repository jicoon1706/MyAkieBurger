import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart';
import 'package:myakieburger/views/manage_user/franchisee_details_page.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

class FranchiseesList extends StatefulWidget {
  const FranchiseesList({super.key});

  @override
  State<FranchiseesList> createState() => _FranchiseesListState();
}

class _FranchiseesListState extends State<FranchiseesList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  Future<List<Map<String, dynamic>>> _fetchFranchisees() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Franchisee')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Convert ISO string to readable date
        String formattedDate = '';
        if (data['created_at'] != null) {
          try {
            final date = DateTime.parse(data['created_at']);
            formattedDate =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          } catch (e) {
            formattedDate = 'Invalid date';
          }
        }

        return {
          'id': doc.id,
          'username': data['username'] ?? 'Unnamed',
          'date': formattedDate,
          'image': 'assets/profile.png',
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetching franchisees: $e");
      return [];
    }
  }

  void _handleViewDetails(String franchiseeId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: FranchiseeDetailsPage(franchiseeId: franchiseeId),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.admin,
      appBar: AppBar(
        backgroundColor: AppColors.admin,
        elevation: 0,
        title: const Text(
          'List of Franchisees',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search franchisees...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                // 💡 CHANGE: Replace Colors.grey.shade900 with AppColors.admin
                fillColor: AppColors.lightPurple,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // 📋 List of franchisees
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFranchisees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No franchisees found',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final franchisees = snapshot.data!
                    .where(
                      (f) => f['username'].toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: franchisees.length,
                  itemBuilder: (context, index) {
                    final franchisee = franchisees[index];
                    return GestureDetector(
                      onTap: () => _handleViewDetails(franchisee['id']),
                      child: Lists(
                        name: franchisee['username'],
                        date: franchisee['date'], // 👈 show created_at date
                        imagePath: franchisee['image'],
                        useProfileIcon: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
