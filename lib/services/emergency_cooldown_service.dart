import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class EmergencyCooldownService {
  static const String _fileName = 'emergency_cooldown.json';
  static const int _cooldownMinutes = 30;

  // Get file path
  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  // Save last emergency report time
  static Future<void> saveLastEmergencyTime() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      final now = DateTime.now().millisecondsSinceEpoch;

      final data = {
        'last_emergency_time': now,
        'saved_at': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving emergency cooldown: $e');
    }
  }

  // Get last emergency report time
  static Future<DateTime?> getLastEmergencyTime() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final timestamp = data['last_emergency_time'] as int?;

      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error reading emergency cooldown: $e');
      return null;
    }
  }

  // Check if user can report emergency (30 minutes cooldown)
  static Future<bool> canReportEmergency() async {
    final lastTime = await getLastEmergencyTime();
    if (lastTime == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastTime);
    return difference.inMinutes >= _cooldownMinutes;
  }

  // Get remaining cooldown time in minutes
  static Future<int> getRemainingCooldownMinutes() async {
    final lastTime = await getLastEmergencyTime();
    if (lastTime == null) return 0;

    final now = DateTime.now();
    final difference = now.difference(lastTime);
    final remaining = _cooldownMinutes - difference.inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  // Get remaining cooldown time in seconds (for countdown display)
  static Future<int> getRemainingCooldownSeconds() async {
    final lastTime = await getLastEmergencyTime();
    if (lastTime == null) return 0;

    final now = DateTime.now();
    final difference = now.difference(lastTime);
    final remainingSeconds = (_cooldownMinutes * 60) - difference.inSeconds;
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  // Clear cooldown (for testing or admin purposes)
  static Future<void> clearCooldown() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing emergency cooldown: $e');
    }
  }

  // Format remaining time as string (e.g., "25:30" for 25 minutes 30 seconds)
  static String formatRemainingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
