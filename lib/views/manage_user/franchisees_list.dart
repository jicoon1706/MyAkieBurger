import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/widgets/lists.dart'; // Reusable Lists widget

class FranchiseesList extends StatefulWidget {
  const FranchiseesList({super.key});

  @override
  State<FranchiseesList> createState() => _FranchiseesListState();
}

class _FranchiseesListState extends State<FranchiseesList> {
  // Sample franchisee data
  final List<Map<String, dynamic>> franchisees = [
    {
      'name': 'Azlan',
      'date': '19/05/2024',
      'total': '250pcs',
      'image': 'assets/profile.png',
    },
    {
      'name': 'Akmal',
      'date': '19/05/2024',
      'total': '500pcs',
      'image': 'assets/profile.png',
    },
    {
      'name': 'Ali',
      'date': '19/05/2024',
      'total': '250pcs',
      'image': 'assets/profile.png',
    },
    {
      'name': 'Ammar',
      'date': '19/05/2024',
      'total': '500pcs',
      'image': 'assets/profile.png',
    },
    {
      'name': 'Yusof',
      'date': '19/05/2024',
      'total': '250pcs',
      'image': 'assets/profile.png',
    },
    {
      'name': 'Ahmad',
      'date': '19/05/2024',
      'total': '500pcs',
      'image': 'assets/profile.png',
    },
  ];

  String searchQuery = '';

  void _handleViewDetails(String franchiseeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$franchiseeName Details'),
        content: const Text('View detailed information about this franchisee.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get filteredFranchisees {
    if (searchQuery.isEmpty) {
      return franchisees;
    }
    return franchisees
        .where(
          (franchisee) => franchisee['name'].toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade900,
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
            child: filteredFranchisees.isEmpty
                ? Center(
                    child: Text(
                      'No franchisees found',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredFranchisees.length,
                    itemBuilder: (context, index) {
                      final franchisee = filteredFranchisees[index];
                      return GestureDetector(
                        onTap: () =>
                            _handleViewDetails(franchisee['name']), // on tap
                        child: Lists(
                          name: franchisee['name'],
                          date:
                              '${franchisee['date']}  •  ${franchisee['total']}',
                          imagePath: franchisee['image'],
                          useProfileIcon: true, // show person icon
                          onDownload: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Downloading ${franchisee['name']} data...',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
