import 'package:flutter/material.dart';
import 'package:myakieburger/routes.dart';
import 'package:myakieburger/widgets/custom_button.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _selectedRole = 'Franchisee'; // Default role
  bool _obscurePassword = true; // 👁️ toggle password visibility

  final List<String> _roles = ['Franchisee', 'Admin', 'Factory Admin'];

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final doc = querySnapshot.docs.first;
      final userData = doc.data();
      final userId = doc.id; // 👈 Get the user ID

      final hashedInput = hashPassword(password);
      final storedPassword = userData['password'];
      final storedRole = (userData['role'] ?? '').toString().trim();

      if (hashedInput != storedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check role
      if (storedRole.toLowerCase() != _selectedRole.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incorrect role selected. Please choose the right role.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 👇 Save user ID to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('franchiseeId', userId);

      String role = userData['role'] ?? 'Franchisee';
      role = role[0].toUpperCase() + role.substring(1).toLowerCase();

      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, Routes.adminMainContainer);
      } else if (role == 'Factory admin') {
        Navigator.pushReplacementNamed(context, Routes.listOfIngredients);
      } else {
        Navigator.pushReplacementNamed(context, Routes.franchiseeMainContainer);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful as $role!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      CustomButton(text: 'Login', onPressed: _handleLogin),

                      const SizedBox(height: 40),

                      // Register link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.register);
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
    );
  }
}
