import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Authentication
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Workout Operations
  Future<void> addWorkout(Map<String, dynamic> workoutData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .add(workoutData);
    } catch (e) {
      print('Error adding workout: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getWorkoutsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      final userId = _auth.currentUser?.uid;
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

  // Exercise Operations
  Future<void> addExercise(
      String workoutId, Map<String, dynamic> exerciseData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .add(exerciseData);
    } catch (e) {
      print('Error adding exercise: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getExercisesStream(String workoutId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .snapshots();
  }

  // Health Metrics Operations
  Future<void> addHealthMetric(Map<String, dynamic> metricData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_metrics')
          .add(metricData);
    } catch (e) {
      print('Error adding health metric: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getHealthMetricsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('health_metrics')
        .orderBy('date', descending: true)
        .snapshots();
  }
}
