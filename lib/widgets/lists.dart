import 'package:flutter/material.dart';
import 'package:myakieburger/theme/app_colors.dart';

class Lists extends StatelessWidget {
  final String name;
  final String date;
  final VoidCallback? onDownload;
  final String imagePath;
  final bool useCalendarIcon; // 👈 new parameter
  final bool useProfileIcon; // 👈 new parameter

  const Lists({
    super.key,
    required this.name,
    required this.date,
    this.onDownload,
    this.imagePath = 'assets/profile.png',
    this.useCalendarIcon = false, // 👈 default = false
    this.useProfileIcon = false, // 👈 default = false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Profile or logo
          // 👇 Show calendar icon OR image
          if (useCalendarIcon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.accentRed,
                size: 22,
              ),
            )
          else if (useProfileIcon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primaryRed,
                size: 24,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                imagePath ?? 'assets/profile.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),

          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: $date',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Download button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}
