import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';
import 'package:myakieburger/routes.dart';

class BalancedIngredients extends StatefulWidget {
  const BalancedIngredients({super.key});

  @override
  State<BalancedIngredients> createState() => _BalancedIngredientsState();
}

class _BalancedIngredientsState extends State<BalancedIngredients> {
  final List<Map<String, dynamic>> ingredients = [
    {'name': 'Roti (pieces)', 'balance': 30},
    {'name': 'Daging (80g)', 'balance': 30},
    {'name': 'Ayam (80g)', 'balance': 30},
    {'name': 'Daging Smoky (100g)', 'balance': 30},
    {'name': 'Kambing (70g)', 'balance': 30},
    {'name': 'Rusa', 'balance': 30},
    {'name': 'Arnab', 'balance': 30},
    {'name': 'Itik', 'balance': 30},
    {'name': 'Roti Hotdog', 'balance': 30},
    {'name': 'Sosej', 'balance': 30},
    {'name': 'Roti Oblong', 'balance': 30},
    {'name': 'Kambing Oblong', 'balance': 30},
    {'name': 'Ayam Oblong', 'balance': 30},
    {'name': 'Daging Oblong', 'balance': 30},
    {'name': 'Cheese (pieces)', 'balance': 30},
    {'name': 'Telur', 'balance': 30},
    {'name': 'Benjo', 'balance': 30},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Balanced Ingredients',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.editIngredients);
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: ingredients.length + 1,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Colors.black54),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingredients Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final item = ingredients[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 15)),
                    Text(
                      item['balance'].toString(),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
