import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsightService {
  static const String _apiKey = 'AIzaSyBRKyZKaWYM7k7EepuqNglTNIDIu87gmCc';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  InsightService() {
    // Initialize Gemini with explicit configuration - THIS SHOULD BE DONE ONCE IN main.dart
    // Gemini.init(
    //   apiKey: _apiKey,
    //   enableDebugging: true,
    // );
  }

  Future<String?> generateInsight(Map<String, dynamic> userData) async {
    try {
      print('Starting insight generation...');

      // Craft a prompt using the user data
      final prompt = '''
        Based on the following user data, generate a personalized health insight:
        - Recent workout: ${userData['recentWorkout'] ?? 'No recent workout'}
        - Workout duration: ${userData['duration'] ?? 'N/A'} minutes
        - Current weight: ${userData['weight'] ?? 'N/A'} kg
        - Sleep hours: ${userData['sleepHours'] ?? 'N/A'} hours
        - Water intake: ${userData['waterIntake'] ?? 'N/A'} glasses
        - Steps: ${userData['steps'] ?? 'N/A'} steps

        The insight should:
        1. Acknowledge their recent activity
        2. Relate it to their health metrics
        3. Provide one specific, actionable tip
        Keep the response under 100 words and make it personal and motivating.
      ''';

      print('Sending prompt to Gemini API...');
      print('Prompt: $prompt');

      // Generate the insight using Gemini with explicit model
      final response = await Gemini.instance.text(
        prompt,
        modelName: 'gemini-1.5-pro',
      );

      print('Received response from Gemini API');
      print('Response: $response');

      if (response == null) {
        print('Error: Gemini API returned null response');
        return null;
      }

      // Access the generated text using .output
      final insight = response.output;

      if (insight == null || insight.isEmpty) {
        print('Error: Generated insight is null or empty');
        return null;
      }

      print('Generated insight: $insight');
      return insight;
    } catch (e, stackTrace) {
      print('Error generating insight: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    try {
      print('Fetching user data for user: $userId'); // Log user id
      // Get user profile
      final profileDoc = await _firestore.collection('users').doc(userId).get();
      final profileData = profileDoc.data() ?? {};
      print('Fetched profile data: $profileData');

      // Get latest workout
      final workoutSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      final workoutData = workoutSnapshot.docs.isNotEmpty
          ? workoutSnapshot.docs.first.data()
          : {};
      print('Fetched workout data: $workoutData');

      // Get latest health metrics
      final healthSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_metrics')
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      final healthData = healthSnapshot.docs.isNotEmpty
          ? healthSnapshot.docs.first.data()
          : {};
      print('Fetched health data: $healthData');

      // Get latest fitness metrics
      final fitnessSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_metrics')
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      final fitnessData = fitnessSnapshot.docs.isNotEmpty
          ? fitnessSnapshot.docs.first.data()
          : {};
      print('Fetched fitness data: $fitnessData');

      return {
        ...profileData,
        ...workoutData,
        ...healthData,
        ...fitnessData,
        'lastWorkoutType': workoutData['type'] ??
            'No recent workout', // Ensure this key is consistent
      };
    } catch (e) {
      print('Error fetching user data: $e');
      return {}; // Return empty map on error
    }
  }

  Future<void> saveInsight(String insight) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).set({
        'insight': insight,
        'insightDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Insight saved to Firestore: $insight'); // Log saving
    } catch (e) {
      print('Error saving insight: $e');
      rethrow; // Re-throw to be caught in generateAndSaveInsight
    }
  }

  Future<String> generateAndSaveInsight() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated, cannot generate insight.');
        return 'User not authenticated.';
      }

      final userData = await _fetchUserData(user.uid);
      if (userData.isEmpty) {
        print('Failed to fetch user data.');
        return 'Could not fetch user data to generate insight.';
      }

      final insight = await generateInsight(userData);
      // Only save if insight generation was successful
      if (insight != null && insight != '') {
        await saveInsight(insight);
      }

      return insight ?? 'No insight generated.';
    } catch (e) {
      print('Error in generateAndSaveInsight: $e');
      return 'Could not generate insight. Please try again.';
    }
  }
}
