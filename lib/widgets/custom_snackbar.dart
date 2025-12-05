import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class CustomSnackbar {

  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  static void show(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.green,
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 1. Determine which sound to play based on color/status
    final String soundPath = (backgroundColor == Colors.green)
        ? 'success_sound.mp3' // Change this to your success sound filename
        : 'error_sound.mp3'; // Change this to your error sound filename

    // 2. Play the sound
    _audioPlayer.play(
      AssetSource(soundPath),
      volume: 1.0, // Adjust volume as needed
    );

    // 3. Show the Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }
}
