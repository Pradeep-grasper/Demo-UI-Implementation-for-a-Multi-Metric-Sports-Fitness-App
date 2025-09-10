import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import 'profile_screen.dart';
import 'fitness_metrics_tab.dart';
import 'health_metrics_tab.dart';
import 'workout_session_tab.dart';
import 'nutrition_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_health_assistant_screen.dart';
import '../widgets/insight_card.dart';
import '../services/insight_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWorkoutExpanded = false;
  int _currentTabIndex = 0;

  // Health metrics
  double _heartRate = 128;
  double _weight = 70;
  double _height = 175;
  double _bmi = 22.5;

  // Exercise metrics
  int _steps = 8432;
  double _distance = 5.2;
  int _calories = 320;
  int _activeTime = 48;
  double _progress = 0.65;

  // Add state for planned and actual pace
  String _plannedPace = 'Moderate pace';
  String _actualPace = 'Slower pace';

  // Controllers for workout form fields
  final TextEditingController _plannedDurationController =
      TextEditingController(text: '30');
  final TextEditingController _plannedDistanceController =
      TextEditingController(text: '5');
  final TextEditingController _actualDurationController =
      TextEditingController(text: '25');
  final TextEditingController _actualDistanceController =
      TextEditingController(text: '4.2');
  final TextEditingController _heartRateController =
      TextEditingController(text: '140');
  final TextEditingController _caloriesController =
      TextEditingController(text: '300');
  final TextEditingController _weightController =
      TextEditingController(text: '70');
  final TextEditingController _bmiController =
      TextEditingController(text: '22.5');

  late final List<Widget> _tabs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _latestHealthMetrics;
  Map<String, dynamic>? _latestActivity;

  final _insightService = InsightService();
  String _currentInsight = 'Loading insights...';
  bool _isLoadingInsight = false;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _buildExerciseTab(),
      const WorkoutSessionTab(),
      const FitnessMetricsTab(),
      const HealthMetricsTab(),
      const NutritionScreen(),
      const AIHealthAssistantScreen(),
    ];
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadUserData();
    _generateNewInsight();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentTabIndex == 0) {
            _showAddExerciseModal();
          } else if (_currentTabIndex == 1) {
            // Workout Metrics tab - no action needed
          } else if (_currentTabIndex == 2) {
            // Fitness Metrics tab - no action needed
          } else if (_currentTabIndex == 3) {
            // Health Metrics tab - no action needed
          } else if (_currentTabIndex == 4) {
            // Nutrition tab - no action needed
          } else if (_currentTabIndex == 5) {
            // AI tab - no action needed
          }
        },
        backgroundColor: const Color(0xFF3366FF),
        child: Icon(
          _currentTabIndex == 0
              ? Icons.fitness_center
              : _currentTabIndex == 1
                  ? Icons.location_on
                  : _currentTabIndex == 2
                      ? Icons.monitor_weight
                      : _currentTabIndex == 3
                          ? Icons.health_and_safety
                          : _currentTabIndex == 4
                          ? Icons.restaurant
                          : Icons.health_and_safety,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fitness Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, size: 32),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 0, right: 16, bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3366FF), Color(0xFF00C6AE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3366FF).withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[800],
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Workout Metrics'),
            Tab(text: 'Fitness Metrics'),
            Tab(text: 'Health Metrics'),
            Tab(text: 'Nutrition'),
            Tab(text: 'AI Assistant'),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightsSection(),
          const SizedBox(height: 24),
          // Health Metrics Overview Section
          Container(
            padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
          ),
        ],
      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                  'HEALTH METRICS OVERVIEW',
                    style: TextStyle(
                    fontSize: 20,
                      fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 20),
                // Heart Rate Card
                _buildHealthMetricCard(
                  title: 'Heart Rate',
                  value: '72',
                  unit: 'bpm',
                  status: 'Normal',
                  statusColor: const Color(0xFF10B981),
                  type: 'Resting heart rate',
                  progress: 0.72,
                  progressColor: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 16),
                // Blood Pressure Card
                _buildBloodPressureCard(),
                const SizedBox(height: 16),
                // Sleep Card
                _buildSleepCard(),
                const SizedBox(height: 16),
                // Steps Card
                _buildStepsCard(),
                const SizedBox(height: 16),
                // Recent Activity Card
                _buildRecentActivityCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    final user = _auth.currentUser; // Get current user

    if (user == null) {
      return const SizedBox(); // Return empty if user is not logged in
    }

    // Use StreamBuilder to listen for real-time changes to the user document
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        print('StreamBuilder connectionState: ${snapshot.connectionState}');
        print('StreamBuilder hasError: ${snapshot.hasError}');
        print('StreamBuilder hasData: ${snapshot.hasData}');
        print('StreamBuilder data: ${snapshot.data?.data()}');

        // Display a loading indicator while data is fetching
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
                  child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(),
      ),
    );
  }

        // Handle errors
        if (snapshot.hasError) {
          print('Error fetching insight stream: ${snapshot.error}');
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                'Error loading insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                fontSize: 16,
              ),
            ),
            ),
          );
        }

        // Get the insight data from the snapshot
        final insightData = snapshot.data?.data();
        final currentInsight = insightData?['insight'] as String?;
        print('Extracted insight: $currentInsight');

        // Display 'No insights available' if insight is null or empty
        if (currentInsight == null || currentInsight.isEmpty) {
          return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    const Text(
                      'INSIGHTS & RECOMMENDATIONS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color:
                            _isLoadingInsight ? Colors.grey : Colors.blueAccent,
                      ),
                      onPressed: _isLoadingInsight ? null : _generateNewInsight,
                    ),
                  ],
                ),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                    'No insights available. Click refresh to generate some.',
                    textAlign: TextAlign.center,
                        style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                        ),
                      ),
              ),
            ),
        ],
          );
        }

        // Display the InsightCard with the fetched insight
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                    'INSIGHTS & RECOMMENDATIONS',
                style: TextStyle(
                      fontSize: 20,
                  fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color:
                          _isLoadingInsight ? Colors.grey : Colors.blueAccent,
                    ),
                    onPressed: _isLoadingInsight ? null : _generateNewInsight,
              ),
            ],
          ),
            ),
            InsightCard(
              insight: currentInsight, // Use the insight from the stream
              onRefresh: _generateNewInsight, // Pass the refresh function
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String message,
    required Color borderColor,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: borderColor,
                ),
              ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthStatusMessage() {
    if (_latestHealthMetrics == null)
      return 'No recent health metrics available.';

    final heartRate = _latestHealthMetrics!['restHeartRate'] ?? 'N/A';
    final sleepDuration = _latestHealthMetrics!['sleepDuration'] ?? 'N/A';
    final sleepQuality = _latestHealthMetrics!['sleepQuality'] ?? 'N/A';

    return 'Your resting heart rate is $heartRate bpm. Sleep duration: $sleepDuration hours with quality rating of $sleepQuality/10.';
  }

  String _getRecommendationsMessage() {
    if (_latestActivity == null)
      return 'Complete your first workout to get personalized recommendations.';

    final workoutType = _latestActivity!['type'] ?? 'workout';
    final duration = _latestActivity!['duration'] ?? 'N/A';

    return 'Based on your recent $workoutType ($duration minutes), consider increasing intensity gradually and maintaining proper hydration.';
  }

  void _showAddExerciseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Exercise',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFormField('Exercise Type', isSelect: true),
                    const SizedBox(height: 16),
                    _buildFormField('Duration (minutes)', value: '30'),
                    const SizedBox(height: 16),
                    _buildFormField('Calories Burned', value: '200'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Exercise added successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366FF),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Exercise',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
    );
  }

  void _showAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Food',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFormField('Meal Type',
                        isSelect: true,
                        options: ['Breakfast', 'Lunch', 'Dinner', 'Snack']),
                    const SizedBox(height: 16),
                    _buildFormField('Food Name',
                        value: 'e.g., Grilled Chicken'),
                    const SizedBox(height: 16),
                    _buildFormField('Calories', value: '250'),
                    const SizedBox(height: 16),
                    _buildFormField('Protein (g)', value: '30'),
                    const SizedBox(height: 16),
                    _buildFormField('Carbs (g)', value: '20'),
                    const SizedBox(height: 16),
                    _buildFormField('Fat (g)', value: '10'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Food added successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366FF),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildFormField(String label,
      {bool isSelect = false, String? value, List<String>? options}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (isSelect)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: options?.first ?? 'Running',
              isExpanded: true,
              underline: const SizedBox(),
              items: (options ??
                      [
                        'Running',
                        'Walking',
                        'Cycling',
                        'Swimming',
                        'Weightlifting',
                        'Yoga'
                      ])
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {},
            ),
          )
        else
          TextField(
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
      ],
    );
  }

  // --- API Integration Methods ---
  Future<void> handleLogWorkout(Map<String, dynamic> workoutData) async {
    final result = await ApiService.logWorkout(workoutData);
    if (result != null && result['insight'] != null) {
      ApiService.showInsightPopup(context, result['insight']);
    } else if (result != null && result['error'] != null) {
      ApiService.showInsightPopup(context, result['error']);
    }
  }

  Future<void> handleLogMeasurement(
      Map<String, dynamic> measurementData) async {
    final result = await ApiService.logMeasurement(measurementData);
    if (result != null && result['insight'] != null) {
      ApiService.showInsightPopup(context, result['insight']);
    } else if (result != null && result['error'] != null) {
      ApiService.showInsightPopup(context, result['error']);
    }
  }

  Future<void> handleGetInsights(int userId) async {
    final result = await ApiService.getInsights(userId);
    if (result != null && result['insight'] != null) {
      ApiService.showInsightPopup(context, result['insight']);
    } else if (result != null && result['error'] != null) {
      ApiService.showInsightPopup(context, result['error']);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load basic profile
      final profileDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('basic_info')
          .doc('profile')
          .get();

      // Load latest health metrics
      final healthMetricsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_metrics')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // Load latest activity
      final activitySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      // Load insight from the user's main document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final insightData = userDoc.data();
        if (insightData != null && insightData.containsKey('insight')) {
          setState(() {
            _currentInsight = insightData['insight'] ?? 'No insight available.';
          });
        }
      }

      setState(() {
        _userProfile = profileDoc.data();
        _latestHealthMetrics = healthMetricsSnapshot.docs.isNotEmpty
            ? healthMetricsSnapshot.docs.first.data()
            : null;
        _latestActivity = activitySnapshot.docs.isNotEmpty
            ? activitySnapshot.docs.first.data()
            : null;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Widget _buildHealthMetricCard({
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required String type,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      strokeWidth: 8,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: progressColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6B7280).withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.favorite,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blood Pressure',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Systolic',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '120',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diastolic',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '80',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Optimal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.bedtime,
                color: Color(0xFF3B82F6),
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sleep',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSleepMetric('Duration', '7.5h'),
                    _buildSleepMetric('Quality', '8/10'),
                    _buildSleepMetric('Recovery', '85%'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Good',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 0.82,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B5CF6)),
                      strokeWidth: 8,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '8,200',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const Text(
                        'steps',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Goal: 10,000 steps',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '1,800 steps remaining',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B82F6).withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.electric_bolt,
                color: Color(0xFFF59E0B),
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ran 5km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '25 min • 5:00/km',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '30s faster',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateNewInsight() async {
    setState(() => _isLoadingInsight = true);
    try {
      final insight = await _insightService.generateAndSaveInsight();
      setState(() => _currentInsight = insight);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating insight: $e')),
      );
    } finally {
      setState(() => _isLoadingInsight = false);
    }
  }
}
