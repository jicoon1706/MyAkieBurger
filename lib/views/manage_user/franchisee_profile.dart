import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';

class FranchiseeProfile extends StatefulWidget {
  const FranchiseeProfile({super.key});

  @override
  State<FranchiseeProfile> createState() => _FranchiseeProfileState();
}

class _FranchiseeProfileState extends State<FranchiseeProfile> {
  bool pushNotifications = true;
  bool faceID = true;

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Navigate to edit profile page'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMyStores() {}
  void _handleSupport() {}
  void _handlePINCode() {}
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add logout logic
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed, // 🔴 matches homepage theme
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // 👈 ensures full screen coverage
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Picture (Icon only)
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppColors.lightRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Name
                const Text(
                  'Coffeestories',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                // Email
                Text(
                  'mark.brock@icloud.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 20),

                // Edit Profile Button
                ElevatedButton(
                  onPressed: _editProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Edit profile',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 32),

                // Inventories Section
                _buildSectionTitle('Inventories'),
                _buildCard(
                  children: [
                    _buildMenuItem(
                      icon: Icons.store_outlined,
                      title: 'My stores',
                      badge: '2',
                      onTap: _handleMyStores,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Preferences Section
                _buildSectionTitle('Preferences'),
                _buildCard(
                  children: [
                    _buildToggleMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Push notifications',
                      value: pushNotifications,
                      onChanged: (v) => setState(() => pushNotifications = v),
                    ),
                    _divider(),
                    _buildMenuItem(
                      icon: Icons.pin_outlined,
                      title: 'PIN Code',
                      onTap: _handlePINCode,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Logout Section
                _buildCard(
                  children: [
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: _handleLogout,
                    ),
                  ],
                ),

                const SizedBox(height: 40), // small consistent bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧱 Helper Widgets
  Widget _buildSectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _buildCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade200, indent: 56);

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? badge,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDestructive ? Colors.red : Colors.grey.shade700,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : Colors.black,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMenuItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryRed,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
