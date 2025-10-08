import 'package:flutter/material.dart';
import 'package:myakieburger/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyAkie Burger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B2E1F), // Akie Burger brand color
        ),
        useMaterial3: true,
      ),
      initialRoute: Routes.login,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}