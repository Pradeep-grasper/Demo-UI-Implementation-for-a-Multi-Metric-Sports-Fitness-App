import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save workout data
  Future<void> saveWorkout({
    required String name,
    required String type,
    required double distance,
    required double duration,
    required String plannedPace,
    required String actualPace,
    required double heartRate,
    required int calories,
    required double weight,
    required double bmi,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .add({
        'name': name,
        'type': type,
        'distance': distance,
        'duration': duration,
        'plannedPace': plannedPace,
        'actualPace': actualPace,
        'heartRate': heartRate,
        'calories': calories,
        'weight': weight,
        'bmi': bmi,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving workout: $e');
      rethrow;
    }
  }

  // Save health metrics
  Future<void> saveHealthMetrics({
    required double restHeartRate,
    required double targetHeartRate,
    required double maxHeartRate,
    required int bpSystolic,
    required int bpDiastolic,
    required String bpTime,
    required double temperature,
    required double bloodOxygen,
    required int bloodSugar,
    required double sleepDuration,
    required int sleepQuality,
    required int recoveryRate,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_metrics')
          .add({
        // Heart Rate
        'restHeartRate': restHeartRate,
        'targetHeartRate': targetHeartRate,
        'maxHeartRate': maxHeartRate,

        // Blood Pressure
        'bpSystolic': bpSystolic,
        'bpDiastolic': bpDiastolic,
        'bpTime': bpTime,

        // Other Vitals
        'temperature': temperature,
        'bloodOxygen': bloodOxygen,
        'bloodSugar': bloodSugar,

        // Sleep Metrics
        'sleepDuration': sleepDuration,
        'sleepQuality': sleepQuality,
        'recoveryRate': recoveryRate,

        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving health metrics: $e');
      rethrow;
    }
  }

  // Get workouts stream
  Stream<QuerySnapshot> getWorkoutsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get health metrics stream
  Stream<QuerySnapshot> getHealthMetricsStream() {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('health_metrics')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId)
          .delete();
    } catch (e) {
      print('Error deleting workout: $e');
      rethrow;
    }
  }

  // Delete health metric
  Future<void> deleteHealthMetric(String metricId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_metrics')
          .doc(metricId)
          .delete();
    } catch (e) {
      print('Error deleting health metric: $e');
      rethrow;
    }
  }

  // Save fitness metrics
  Future<void> saveFitnessMetrics({
    required double weight,
    required double height,
    required double bmi,
    required double bodyFat,
    required double muscleMass,
    required double waterPercentage,
    required double boneMass,
    required double bmr,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_metrics')
          .add({
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'bodyFat': bodyFat,
        'muscleMass': muscleMass,
        'waterPercentage': waterPercentage,
        'boneMass': boneMass,
        'bmr': bmr,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving fitness metrics: $e');
      rethrow;
    }
  }

  // Get fitness metrics stream
  Stream<QuerySnapshot> getFitnessMetricsStream() {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('fitness_metrics')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Delete fitness metric
  Future<void> deleteFitnessMetric(String metricId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_metrics')
          .doc(metricId)
          .delete();
    } catch (e) {
      print('Error deleting fitness metric: $e');
      rethrow;
    }
  }

  Future<void> saveAllFitnessData(Map<String, dynamic> fitnessData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the current timestamp
      final timestamp = FieldValue.serverTimestamp();

      // Prepare the data with timestamp
      final dataToSave = {
        ...fitnessData,
        'timestamp': timestamp,
      };

      // Save to Firestore under users/{userId}/fitness_metrics
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fitness_metrics')
          .add(dataToSave);

      print('Fitness data saved successfully to Firebase');
    } catch (e) {
      print('Error saving fitness data to Firebase: $e');
      throw Exception('Failed to save fitness data: $e');
    }
  }

  Future<Map<String, dynamic>?> getFitnessMetrics() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_data')
          .doc('metrics')
          .get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print('Error getting fitness metrics: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRecentActivity() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sports_activities')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return querySnapshot.docs.first.data();
    } catch (e) {
      print('Error getting recent activity: $e');
      return null;
    }
  }

  Future<void> saveWorkoutMetrics(Map<String, dynamic> workoutData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add(workoutData);
    } catch (e) {
      print('Error saving workout metrics: $e');
      rethrow;
    }
  }
}
