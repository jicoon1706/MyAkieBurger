import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/providers/user_controller.dart';
import 'package:myakieburger/services/auth_service.dart';
import 'package:myakieburger/domains/user_model.dart';
import 'package:myakieburger/widgets/custom_snackbar.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  final _formKey = GlobalKey<FormState>();
  final UserController _userController = UserController();

  final TextEditingController _stallNameController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  bool _isLoading = true;
  UserModel? _user;

  // Region (Dropdown) — All Malaysian States
  final List<String> _regions = [
    // Northern Region
    'Perlis',
    'Kedah',
    'Pulau Pinang',
    'Perak',

    // Central Region
    'Selangor',
    'Wilayah Persekutuan Kuala Lumpur',
    'Wilayah Persekutuan Putrajaya',

    // Southern Region
    'Negeri Sembilan',
    'Melaka',
    'Johor',

    // East Coast Region
    'Pahang',
    'Terengganu',
    'Kelantan',

    // East Malaysia
    'Sabah',
    'Sarawak',
    'Wilayah Persekutuan Labuan',
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      final userId = await getLoggedInUserId();
      if (userId == null) {
        CustomSnackbar.show(
          context,
          message: 'No logged-in user found',
          backgroundColor: Colors.red,
          icon: Icons.close,
        );
        return;
      }

      final user = await _userController.getUserById(userId);

      if (user != null) {
        setState(() {
          _user = user;
          _stallNameController.text = user.stallName ?? '';
          _regionController.text = user.region ?? '';
          _isLoading = false;
        });
      } else {
        CustomSnackbar.show(
          context,
          message: 'User data not found',
          backgroundColor: Colors.red,
          icon: Icons.close,
        );
      }
    } catch (e) {
      print('❌ Error loading store data: $e');
      CustomSnackbar.show(
        context,
        message: 'Failed to load store data: $e',
        backgroundColor: Colors.red,
        icon: Icons.close,
      );
    }
  }

  Future<void> _saveStoreData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final userId = await getLoggedInUserId();
      if (userId == null) return;

      final updatedUser = _user!.copyWith(
        stallName: _stallNameController.text.trim(),
        region: _regionController.text.trim(),
      );

      await _userController.updateStoreInfo(
        userId,
        stallName: _stallNameController.text.trim(),
        region: _regionController.text.trim(),
      );

      setState(() => _isLoading = false);

      CustomSnackbar.show(
        context,
        message: 'Store info updated successfully!',
        backgroundColor: Colors.green,
        icon: Icons.check,
      );

      Navigator.pop(context, updatedUser);
    } catch (e) {
      setState(() => _isLoading = false);

      CustomSnackbar.show(
        context,
        message: 'Failed to update store info: $e',
        backgroundColor: Colors.red,
        icon: Icons.close,
      );
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
        centerTitle: true,
        title: const Text(
          'My Store',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Stall Name
                        TextFormField(
                          controller: _stallNameController,
                          decoration: InputDecoration(
                            labelText: 'Stall Name',
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your stall name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Replace your existing Region TextFormField with this:
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _regionController.text.isNotEmpty
                              ? _regionController.text
                              : null,
                          items: _regions.map((region) {
                            return DropdownMenuItem<String>(
                              value: region,
                              child: Text(region),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: 'Region',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _regionController.text = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your region';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveStoreData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
