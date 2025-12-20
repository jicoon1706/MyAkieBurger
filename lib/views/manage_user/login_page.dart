import 'package:flutter/material.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/widgets/custom_button.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myakieburger/services/auth_service.dart'; // 🆕 Import auth service
import '../../widgets/custom_snackbar.dart';

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Franchisee';
  bool _obscurePassword = true;
  bool _isLoading = false; // 🆕 Add loading state

  final List<String> _roles = [
    'Franchisee',
    'Admin',
    'Factory Admin',
    'Delivery Agent',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Please fill in all fields',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    // 🆕 Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get()
        .timeout(
          const Duration(seconds: 10), // 10 second timeout
          onTimeout: () {
            throw Exception('Connection timeout. Please check your internet connection.');
          },
        );

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        CustomSnackbar.show(
          context,
          message: 'User not found',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
        return;
      }

      final doc = querySnapshot.docs.first;
      final userData = doc.data();
      final userId = doc.id;

      final hashedInput = hashPassword(password);
      final storedPassword = userData['password'];
      final storedRole = (userData['role'] ?? '').toString().trim();

      if (hashedInput != storedPassword) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        CustomSnackbar.show(
          context,
          message: 'Incorrect password',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
        return;
      }

      if (storedRole.toLowerCase() != _selectedRole.toLowerCase()) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        CustomSnackbar.show(
          context,
          message: 'Incorrect role selected. Please choose the right role.',
          backgroundColor: Colors.redAccent,
          icon: Icons.warning_amber_rounded,
        );
        return;
      }

      // Save user session
      String role = userData['role'] ?? 'Franchisee';
      await saveUserSession(userId, role);

      print('✅ User session saved - ID: $userId, Role: $role');

      if (!mounted) return;

      // Navigate by role
      if (role.toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, Routes.adminMainContainer);
      } else if (role.toLowerCase() == 'factory admin') {
        Navigator.pushReplacementNamed(context, Routes.fad);
      } else if (role.toLowerCase() == 'delivery agent') {
        Navigator.pushReplacementNamed(context, Routes.DAMainContainer);
      } else {
        Navigator.pushReplacementNamed(context, Routes.franchiseeMainContainer);
      }

      CustomSnackbar.show(
        context,
        message: 'Login successful as $role!',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      print('❌ Login error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      CustomSnackbar.show(
        context,
        message: 'Login failed: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header with logo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: const BoxDecoration(color: Color(0xFF8B2E1F)),
                    child: Center(
                      child: Image.asset(
                        'assets/logoAkie.png',
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Login form
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Login to your Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isLoading, // 🆕 Disable when loading
                            decoration: InputDecoration(
                              labelText: 'Username',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password field with eye icon
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading, // 🆕 Disable when loading
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Roles dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            onChanged: _isLoading // 🆕 Disable when loading
                                ? null
                                : (String? newValue) {
                                    setState(() {
                                      _selectedRole = newValue!;
                                    });
                                  },
                            decoration: InputDecoration(
                              labelText: 'Roles',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Login button with loading state
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB83D2A),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Register link
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                          context, Routes.register);
                                    },
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: TextStyle(
                                        color: Color(0xFFB83D2A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 🆕 Full screen loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB83D2A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}