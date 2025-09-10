import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your computer's local IP if running on a device/emulator
  static const String baseUrl =
      'http://192.168.43.3:5000'; // Your computer's local IP address

  static Future<Map<String, dynamic>?> logWorkout(
      Map<String, dynamic> workoutData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/workout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(workoutData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return {'error': jsonDecode(response.body)['error'] ?? 'Unknown error'};
    }
  }

  static Future<Map<String, dynamic>?> logMeasurement(
      Map<String, dynamic> measurementData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/measurement'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(measurementData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return {'error': jsonDecode(response.body)['error'] ?? 'Unknown error'};
    }
  }

  static Future<Map<String, dynamic>?> getInsights(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/insights/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'error': jsonDecode(response.body)['error'] ?? 'Unknown error'};
    }
  }

  static void showInsightPopup(BuildContext context, dynamic insight) {
    if (insight is Map<String, dynamic>) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Workout Insight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (insight['summary'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(insight['summary'],
                      style: const TextStyle(fontSize: 16)),
                ),
              if (insight['metrics'] != null && insight['metrics'].isNotEmpty)
                ...insight['metrics'].entries.map<Widget>((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(_getMetricIcon(entry.key),
                              size: 18, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(_formatMetric(entry.key, entry.value),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              if (insight['positive_feedback'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(insight['positive_feedback'],
                      style: const TextStyle(color: Colors.blue)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Insight'),
          content: Text(insight?.toString() ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  static IconData _getMetricIcon(String key) {
    switch (key) {
      case 'distance_difference':
        return Icons.straighten;
      case 'heart_rate':
        return Icons.favorite;
      case 'calories_burned':
        return Icons.local_fire_department;
      case 'weight':
        return Icons.monitor_weight;
      case 'bmi':
        return Icons.accessibility_new;
      default:
        return Icons.info_outline;
    }
  }

  static String _formatMetric(String key, dynamic value) {
    switch (key) {
      case 'distance_difference':
        return 'Distance Difference: ${value} km';
      case 'heart_rate':
        return 'Heart Rate: ${value} bpm';
      case 'calories_burned':
        return 'Calories Burned: ${value} kcal';
      case 'weight':
        return 'Weight: ${value} kg';
      case 'bmi':
        return 'BMI: ${value}';
      default:
        return '$key: $value';
    }
  }
}
