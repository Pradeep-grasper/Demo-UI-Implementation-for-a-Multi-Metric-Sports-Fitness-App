import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:flutter/services.dart';

class FitnessMetricsTab extends StatefulWidget {
  const FitnessMetricsTab({Key? key}) : super(key: key);

  @override
  State<FitnessMetricsTab> createState() => _FitnessMetricsTabState();
}

class _FitnessMetricsTabState extends State<FitnessMetricsTab> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Form controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bmiController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _waterPercentageController = TextEditingController();
  final _boneMassController = TextEditingController();
  final _bmrController = TextEditingController();

  // Fitness attributes
  double _speed = 5;
  double _endurance = 5;
  double _agility = 5;
  double _flexibility = 5;
  double _coreStrength = 5;

  // List to store sports activities
  final List<Map<String, dynamic>> _sportsActivities = [];

  // Current month metrics
  Map<String, double> _currentMetrics = {
    'speed': 7.5,
    'endurance': 8.0,
    'agility': 6.5,
    'flexibility': 7.0,
    'core': 7.5,
  };

  // Last month metrics
  Map<String, double> _lastMonthMetrics = {
    'speed': 6.5,
    'endurance': 7.0,
    'agility': 6.5,
    'flexibility': 6.0,
    'core': 7.0,
  };

  // Recent activity
  Map<String, dynamic>? _recentActivity;

  @override
  void initState() {
    super.initState();
    _loadFitnessData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bmiController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _waterPercentageController.dispose();
    _boneMassController.dispose();
    _bmrController.dispose();
    super.dispose();
  }

  Future<void> _loadFitnessData() async {
    setState(() => _isLoading = true);
    try {
      // Load fitness metrics from Firestore
      final metrics = await _firestoreService.getFitnessMetrics();
      if (metrics != null) {
        setState(() {
          _currentMetrics = Map<String, double>.from(metrics['current'] ?? {});
          _lastMonthMetrics =
              Map<String, double>.from(metrics['lastMonth'] ?? {});
        });
      }

      // Load recent activity
      final activity = await _firestoreService.getRecentActivity();
      if (activity != null) {
        setState(() {
          _recentActivity = activity;
        });
      }
    } catch (e) {
      print('Error loading fitness data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _averageScore {
    final values = _currentMetrics.values;
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> _saveFitnessMetrics() async {
    setState(() => _isLoading = true);

    try {
      // Collect fitness attribute data
      final fitnessAttributes = {
        'speed': _speed,
        'endurance': _endurance,
        'agility': _agility,
        'flexibility': _flexibility,
        'coreStrength': _coreStrength,
      };

      // Process sports activities data
      final processedSportsActivities = _sportsActivities.map((sport) {
        final processedSport = Map<String, dynamic>.from(sport);

        // Convert string values to numbers where appropriate
        if (sport['points'] != null) {
          processedSport['points'] = int.tryParse(sport['points']) ?? 0;
        }
        if (sport['assists'] != null) {
          processedSport['assists'] = int.tryParse(sport['assists']) ?? 0;
        }
        if (sport['rebounds'] != null) {
          processedSport['rebounds'] = int.tryParse(sport['rebounds']) ?? 0;
        }
        if (sport['goals'] != null) {
          processedSport['goals'] = int.tryParse(sport['goals']) ?? 0;
        }
        if (sport['sets_won'] != null) {
          processedSport['sets_won'] = int.tryParse(sport['sets_won']) ?? 0;
        }
        if (sport['aces'] != null) {
          processedSport['aces'] = int.tryParse(sport['aces']) ?? 0;
        }
        if (sport['blocks'] != null) {
          processedSport['blocks'] = int.tryParse(sport['blocks']) ?? 0;
        }
        if (sport['runs'] != null) {
          processedSport['runs'] = int.tryParse(sport['runs']) ?? 0;
        }
        if (sport['wickets'] != null) {
          processedSport['wickets'] = int.tryParse(sport['wickets']) ?? 0;
        }
        if (sport['distance'] != null) {
          processedSport['distance'] =
              double.tryParse(sport['distance']) ?? 0.0;
        }
        if (sport['time_taken_seconds'] != null) {
          processedSport['time_taken_seconds'] =
              int.tryParse(sport['time_taken_seconds']) ?? 0;
        }
        if (sport['total_time_played_minutes'] != null) {
          processedSport['total_time_played_minutes'] =
              int.tryParse(sport['total_time_played_minutes']) ?? 0;
        }

        return processedSport;
      }).toList();

      // Combine all data
      final allFitnessData = {
        'fitnessAttributes': fitnessAttributes,
        'sportsActivities': processedSportsActivities,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Save to Firebase
      await _firestoreService.saveAllFitnessData(allFitnessData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitness data saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving fitness data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isNumber = true,
    double? step,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSportsSection(),
          if (_sportsActivities.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildFitnessMetricsCard(),
          ],
          const SizedBox(height: 24),
          // Progress Charts Section
          _buildProgressCharts(),
          const SizedBox(height: 24),
          // Fitness Attributes Section
          _buildFitnessAttributes(),
          const SizedBox(height: 24),
          // Recent Activity Section
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildSportsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        const Text(
                          'Athletic Sports Performance',
                    style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                        Text(
                          'Add your daily sports activities',
                    style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddSportModal,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Sport'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_sportsActivities.isEmpty)
                Center(
              child: Container(
                    padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                            Icons.sports_soccer,
                            size: 48,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sports activities added yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first sport activity to track your performance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
              ),
            ),
          ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sportsActivities.length,
                  itemBuilder: (context, index) {
                    final sport = _sportsActivities[index];
                    return _buildSportCard(sport, index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportCard(Map<String, dynamic> sport, int index) {
    String timeDisplay = '';
    if (sport['time_taken_seconds'] != null) {
      final totalSeconds = int.tryParse(sport['time_taken_seconds']) ?? 0;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      timeDisplay = 'Time: ${minutes} min ${seconds} sec';
    } else if (sport['total_time_played_minutes'] != null) {
      final totalMinutes =
          int.tryParse(sport['total_time_played_minutes']) ?? 0;
      if (totalMinutes >= 60) {
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        timeDisplay = 'Total Time: ${hours} hr ${minutes} min';
      } else {
        timeDisplay = 'Total Time: ${totalMinutes} min';
      }
    }

    String metricsDisplay = '';
    switch (sport['type']) {
      case 'Basketball':
        metricsDisplay =
            'Points: ${sport['points']} | Assists: ${sport['assists']} | Rebounds: ${sport['rebounds']}';
        break;
      case 'Football':
        metricsDisplay =
            'Goals: ${sport['goals']} | Assists: ${sport['assists']}';
        break;
      case 'Tennis':
        metricsDisplay =
            'Sets Won: ${sport['sets_won']} | Aces: ${sport['aces']}';
        break;
      case 'Volleyball':
        metricsDisplay =
            'Points: ${sport['points']} | Blocks: ${sport['blocks']} | Aces: ${sport['aces']}';
        break;
      case 'Cricket':
        metricsDisplay =
            'Runs: ${sport['runs']} | Wickets: ${sport['wickets']}';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSportIcon(sport['type']),
            color: const Color(0xFF3366FF),
          ),
        ),
        title: Text(
          sport['type'],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            const SizedBox(height: 4),
            Text(
              'Level: ${sport['level']}',
                            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (sport['date'] != null) ...[
                        const SizedBox(height: 4),
              Text(
                'Date: ${sport['date'].toString().split('T')[0]}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            if (sport['distance'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Distance: ${sport['distance']} km',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            if (timeDisplay.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeDisplay,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            if (metricsDisplay.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                metricsDisplay,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
                              setState(() {
              _sportsActivities.removeAt(index);
                              });
                            },
                          ),
      ),
    );
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'swimming':
        return Icons.pool;
      case 'cycling':
        return Icons.directions_bike;
      case 'basketball':
        return Icons.sports_basketball;
      case 'football':
        return Icons.sports_soccer;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'cricket':
        return Icons.sports_cricket;
      default:
        return Icons.sports;
    }
  }

  void _showAddSportModal() {
    String selectedSport = 'Running';
    String level = 'Beginner';
    final distanceController = TextEditingController();
    String selectedDistanceUnit = 'km';
    final timeController = TextEditingController();
    String selectedTimeUnit = 'minutes';
    final totalTimePlayedController = TextEditingController();
    String selectedTotalTimeUnit = 'minutes';

    // Sport-specific metric controllers
    final basketballPointsController = TextEditingController();
    final basketballAssistsController = TextEditingController();
    final basketballReboundsController = TextEditingController();

    final footballGoalsController = TextEditingController();
    final footballAssistsController = TextEditingController();

    final tennisSetsWonController = TextEditingController();
    final tennisAcesController = TextEditingController();

    final volleyballPointsController = TextEditingController();
    final volleyballBlocksController = TextEditingController();
    final volleyballAcesController = TextEditingController();

    final cricketRunsController = TextEditingController();
    final cricketWicketsController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    bool isCustomSport = false;
    final customSportController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Sport Activity',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      ListTile(
                        leading: Icon(Icons.calendar_today,
                            color: Color(0xFF3366FF)),
                        title: Text('Date',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 16)),
                        trailing: TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Color(0xFF3366FF),
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                    dialogBackgroundColor: Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null &&
                                pickedDate != selectedDate) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text(
                            '${selectedDate.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                                fontSize: 16, color: Color(0xFF3366FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSportTypeDropdown(
                        selectedSport,
                        (newValue) {
                          setState(() {
                            selectedSport = newValue!;
                            isCustomSport = newValue == 'Other';
                            distanceController.clear();
                            timeController.clear();
                            totalTimePlayedController.clear();
                            basketballPointsController.clear();
                            basketballAssistsController.clear();
                            basketballReboundsController.clear();
                            footballGoalsController.clear();
                            footballAssistsController.clear();
                            tennisSetsWonController.clear();
                            tennisAcesController.clear();
                            volleyballPointsController.clear();
                            volleyballBlocksController.clear();
                            volleyballAcesController.clear();
                            cricketRunsController.clear();
                            cricketWicketsController.clear();
                            customSportController.clear();
                            selectedDistanceUnit = 'km';
                            selectedTimeUnit = 'minutes';
                            selectedTotalTimeUnit = 'minutes';
                          });
                        },
                        [
                          'Running',
                          'Swimming',
                          'Cycling',
                          'Basketball',
                          'Football',
                          'Tennis',
                          'Volleyball',
                          'Cricket',
                          'Other'
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isCustomSport) ...[
                        TextField(
                          controller: customSportController,
                          decoration: InputDecoration(
                            labelText: 'Custom Sport Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3366FF), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Total Time Played',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: totalTimePlayedController,
                                decoration: InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.timer),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: selectedTotalTimeUnit,
                              items: ['minutes', 'hours'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedTotalTimeUnit = newValue!;
                                });
                              },
                            ),
            ],
          ),
          const SizedBox(height: 16),
                        TextField(
                          controller: TextEditingController(),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes about the game',
                            hintText:
                                'Enter any significant details about your performance, achievements, or observations',
                            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
                            prefixIcon: const Icon(Icons.note),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),
                      ] else if (['Running', 'Swimming', 'Cycling']
                          .contains(selectedSport)) ...[
                        const Text(
                          'Distance',
              style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: distanceController,
                                decoration: InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.directions_run),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^[0-9]*\.?[0-9]*'))
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: selectedDistanceUnit,
                              items: ['km', 'm'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedDistanceUnit = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Time Taken',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
        Row(
          children: [
                            Expanded(
                              child: TextField(
                                controller: timeController,
                                decoration: InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.timer),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: selectedTimeUnit,
                              items: ['minutes', 'seconds'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedTimeUnit = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else if ([
                        'Basketball',
                        'Football',
                        'Tennis',
                        'Volleyball',
                        'Cricket'
                      ].contains(selectedSport)) ...[
                        const Text(
                          'Total Time Played',
            style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: totalTimePlayedController,
                                decoration: InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
                                  prefixIcon: const Icon(Icons.timer),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: selectedTotalTimeUnit,
                              items: ['minutes', 'hours'].map((String value) {
                                return DropdownMenuItem<String>(
                value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  selectedTotalTimeUnit = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (selectedSport == 'Basketball') ...[
                          Row(
                children: [
                  Expanded(
                    child: TextField(
                                  controller: basketballPointsController,
                                  decoration: InputDecoration(
                                    labelText: 'Points',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.sports_basketball),
                      ),
                      keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: basketballAssistsController,
                                  decoration: InputDecoration(
                                    labelText: 'Assists',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.people),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: basketballReboundsController,
                                  decoration: InputDecoration(
                                    labelText: 'Rebounds',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.sports),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                ],
              ),
            ),
        ],
      ),
                        ] else if (selectedSport == 'Football') ...[
                          Row(
            children: [
                              Expanded(
                                child: TextField(
                                  controller: footballGoalsController,
                                  decoration: InputDecoration(
                                    labelText: 'Goals',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.sports_soccer),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: footballAssistsController,
                                  decoration: InputDecoration(
                                    labelText: 'Assists',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.people),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                ),
              ],
            ),
                        ] else if (selectedSport == 'Tennis') ...[
                          Row(
              children: [
                              Expanded(
                                child: TextField(
                                  controller: tennisSetsWonController,
                                  decoration: InputDecoration(
                                    labelText: 'Sets Won',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.sports_tennis),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: tennisAcesController,
                                  decoration: InputDecoration(
                                    labelText: 'Aces',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.star),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
          ),
        ],
      ),
                        ] else if (selectedSport == 'Volleyball') ...[
          Row(
            children: [
                              Expanded(
                                child: TextField(
                                  controller: volleyballPointsController,
                                  decoration: InputDecoration(
                                    labelText: 'Points',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.sports_volleyball),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
              ),
              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: volleyballBlocksController,
                                  decoration: InputDecoration(
                                    labelText: 'Blocks',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.block),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: volleyballAcesController,
                                  decoration: InputDecoration(
                                    labelText: 'Aces',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.star),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else if (selectedSport == 'Cricket') ...[
                          Row(
                children: [
                              Expanded(
                                child: TextField(
                                  controller: cricketRunsController,
                                  decoration: InputDecoration(
                                    labelText: 'Runs',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.sports_cricket),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                ],
              ),
            ),
                              const SizedBox(width: 8),
            Expanded(
                                child: TextField(
                                  controller: cricketWicketsController,
                                  decoration: InputDecoration(
                                    labelText: 'Wickets',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.sports),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                    const SizedBox(height: 16),
                      ],
                      _buildFormField(
                        'Level',
                        isSelect: true,
                        value: level,
                        options: [
                          'Beginner',
                          'Intermediate',
                          'Advanced',
                          'Professional'
                        ],
                        onChanged: (value) {
                          setState(() {
                            level = value!;
                          });
                        },
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                          this.setState(() {
                            final sportData = <String, dynamic>{
                              'type': isCustomSport
                                  ? customSportController.text
                                  : selectedSport,
                              'level': level,
                              'date': selectedDate.toIso8601String(),
                            };

                            // Add distance and time for endurance sports
                            if (['Running', 'Swimming', 'Cycling']
                                .contains(selectedSport)) {
                              final distanceValue =
                                  double.tryParse(distanceController.text) ??
                                      0.0;
                              if (selectedDistanceUnit == 'm') {
                                sportData['distance'] =
                                    (distanceValue / 1000).toStringAsFixed(2);
                              } else {
                                sportData['distance'] =
                                    distanceValue.toStringAsFixed(2);
                              }

                              final timeValue =
                                  int.tryParse(timeController.text) ?? 0;
                              if (selectedTimeUnit == 'minutes') {
                                sportData['time_taken_seconds'] =
                                    (timeValue * 60).toString();
                              } else {
                                sportData['time_taken_seconds'] =
                                    timeValue.toString();
                              }
                            }

                            // Add total time played and sport-specific metrics
                            if ([
                              'Basketball',
                              'Football',
                              'Tennis',
                              'Volleyball',
                              'Cricket'
                            ].contains(selectedSport)) {
                              final totalTimeValue = int.tryParse(
                                      totalTimePlayedController.text) ??
                                  0;
                              if (selectedTotalTimeUnit == 'hours') {
                                sportData['total_time_played_minutes'] =
                                    (totalTimeValue * 60).toString();
                              } else {
                                sportData['total_time_played_minutes'] =
                                    totalTimeValue.toString();
                              }

                              // Add sport-specific metrics
                              switch (selectedSport) {
                                case 'Basketball':
                                  sportData['points'] =
                                      basketballPointsController.text;
                                  sportData['assists'] =
                                      basketballAssistsController.text;
                                  sportData['rebounds'] =
                                      basketballReboundsController.text;
                                  break;
                                case 'Football':
                                  sportData['goals'] =
                                      footballGoalsController.text;
                                  sportData['assists'] =
                                      footballAssistsController.text;
                                  break;
                                case 'Tennis':
                                  sportData['sets_won'] =
                                      tennisSetsWonController.text;
                                  sportData['aces'] = tennisAcesController.text;
                                  break;
                                case 'Volleyball':
                                  sportData['points'] =
                                      volleyballPointsController.text;
                                  sportData['blocks'] =
                                      volleyballBlocksController.text;
                                  sportData['aces'] =
                                      volleyballAcesController.text;
                                  break;
                                case 'Cricket':
                                  sportData['runs'] =
                                      cricketRunsController.text;
                                  sportData['wickets'] =
                                      cricketWicketsController.text;
                                  break;
                              }
                            }

                            _sportsActivities.add(sportData);
                          });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366FF),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                          elevation: 2,
                      ),
                      child: const Text(
                          'Add Sport',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                            fontSize: 16,
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
      ),
    );
  }

  Widget _buildSportTypeDropdown(
    String value,
    ValueChanged<String?> onChanged,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
          'Sport Type',
                    style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: options
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessMetricsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Text(
              'Fitness Metrics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    ElevatedButton(
              onPressed: _isLoading ? null : _saveFitnessMetrics,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3366FF),
                minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Fitness Data',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        _buildMetricSlider('Speed', _speed, (value) {
          setState(() => _speed = value);
        }),
        const SizedBox(height: 16),
        _buildMetricSlider('Endurance', _endurance, (value) {
          setState(() => _endurance = value);
        }),
        const SizedBox(height: 16),
        _buildMetricSlider('Agility', _agility, (value) {
          setState(() => _agility = value);
        }),
        const SizedBox(height: 16),
        _buildMetricSlider('Flexibility', _flexibility, (value) {
          setState(() => _flexibility = value);
        }),
        const SizedBox(height: 16),
        _buildMetricSlider('Core Strength', _coreStrength, (value) {
          setState(() => _coreStrength = value);
        }),
      ],
    );
  }

  Widget _buildMetricSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (1-10)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF3366FF),
                  inactiveTrackColor: const Color(0xFFE5E7EB),
                  thumbColor: const Color(0xFF3366FF),
                  overlayColor: const Color(0xFF3366FF).withOpacity(0.1),
                  valueIndicatorColor: const Color(0xFF3366FF),
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: value,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: value.round().toString(),
                  onChanged: onChanged,
                ),
              ),
            ),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                value.round().toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label, {
    bool isSelect = false,
    List<String>? options,
    ValueChanged<String?>? onChanged,
    String? value,
  }) {
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
              value: value ?? options?.first,
              isExpanded: true,
              underline: const SizedBox(),
              items: options
                  ?.map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }

  String _getSportSpecificMetricLabel(String sportType) {
    switch (sportType) {
      case 'Basketball':
        return 'Points, Assists, Rebounds (e.g., 15/5/8)';
      case 'Football':
        return 'Goals, Assists (e.g., 2/1)';
      case 'Tennis':
        return 'Sets Won, Aces (e.g., 2-0, 5 aces)';
      case 'Volleyball':
        return 'Points, Blocks, Aces (e.g., 12/3/2)';
      case 'Cricket':
        return 'Runs, Wickets (e.g., 45/2)';
      default:
        return 'Other Significant Metric';
    }
  }

  Widget _buildProgressCharts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'PROGRESS CHARTS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: _currentMetrics.entries
                        .map((e) => RadarEntry(value: e.value))
                        .toList(),
                    fillColor: const Color(0xFF3B82F6).withOpacity(0.3),
                    borderColor: const Color(0xFF3B82F6),
                    borderWidth: 2,
                  ),
                  RadarDataSet(
                    dataEntries: _lastMonthMetrics.entries
                        .map((e) => RadarEntry(value: e.value))
                        .toList(),
                    fillColor: Colors.grey.withOpacity(0.1),
                    borderColor: Colors.grey,
                    borderWidth: 1,
                  ),
                ],
                titleTextStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
                tickCount: 5,
                ticksTextStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                ),
                getTitle: (index, angle) {
                  final titles = [
                    'Speed',
                    'Endurance',
                    'Agility',
                    'Flexibility',
                    'Core'
                  ];
                  return RadarChartTitle(
                    text: titles[index],
                    angle: angle,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: const Color(0xFF3B82F6),
                label: 'Current Month',
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                color: Colors.grey,
                label: 'Last Month',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessAttributes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              const Text(
                'FITNESS ATTRIBUTES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
              ),
            ),
            Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              child: Text(
                  'Avg: ${_averageScore.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._currentMetrics.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAttributeCard(
                  title: entry.key.toUpperCase(),
                  score: entry.value,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAttributeCard({
    required String title,
    required double score,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: score / 10,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6)),
                      strokeWidth: 8,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${score.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score out of 10',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6B7280).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_sportsActivities.isEmpty) return const SizedBox.shrink();

    // Get the most recent activity
    final recentActivity = _sportsActivities.first;
    String sportType = recentActivity['type'] ?? 'Unknown';
    String level = recentActivity['level'] ?? 'Beginner';
    String date = recentActivity['date'] != null
        ? DateTime.parse(recentActivity['date'])
            .toLocal()
            .toString()
            .split('T')[0]
        : 'Today';

    // Get sport-specific metrics
    String metricsDisplay = '';
    List<Map<String, String>> statBlocks = [];

    switch (sportType) {
      case 'Basketball':
        metricsDisplay =
            'Points: ${recentActivity['points'] ?? '0'} | Assists: ${recentActivity['assists'] ?? '0'} | Rebounds: ${recentActivity['rebounds'] ?? '0'}';
        statBlocks = [
          {
            'value': recentActivity['points']?.toString() ?? '0',
            'label': 'Points'
          },
          {
            'value': recentActivity['assists']?.toString() ?? '0',
            'label': 'Assists'
          },
          {
            'value': recentActivity['rebounds']?.toString() ?? '0',
            'label': 'Rebounds'
          },
        ];
        break;
      case 'Football':
        metricsDisplay =
            'Goals: ${recentActivity['goals'] ?? '0'} | Assists: ${recentActivity['assists'] ?? '0'}';
        statBlocks = [
          {
            'value': recentActivity['goals']?.toString() ?? '0',
            'label': 'Goals'
          },
          {
            'value': recentActivity['assists']?.toString() ?? '0',
            'label': 'Assists'
          },
        ];
        break;
      case 'Tennis':
        metricsDisplay =
            'Sets Won: ${recentActivity['sets_won'] ?? '0'} | Aces: ${recentActivity['aces'] ?? '0'}';
        statBlocks = [
          {
            'value': recentActivity['sets_won']?.toString() ?? '0',
            'label': 'Sets Won'
          },
          {'value': recentActivity['aces']?.toString() ?? '0', 'label': 'Aces'},
        ];
        break;
      case 'Volleyball':
        metricsDisplay =
            'Points: ${recentActivity['points'] ?? '0'} | Blocks: ${recentActivity['blocks'] ?? '0'} | Aces: ${recentActivity['aces'] ?? '0'}';
        statBlocks = [
          {
            'value': recentActivity['points']?.toString() ?? '0',
            'label': 'Points'
          },
          {
            'value': recentActivity['blocks']?.toString() ?? '0',
            'label': 'Blocks'
          },
          {'value': recentActivity['aces']?.toString() ?? '0', 'label': 'Aces'},
        ];
        break;
      case 'Cricket':
        metricsDisplay =
            'Runs: ${recentActivity['runs'] ?? '0'} | Wickets: ${recentActivity['wickets'] ?? '0'}';
        statBlocks = [
          {'value': recentActivity['runs']?.toString() ?? '0', 'label': 'Runs'},
          {
            'value': recentActivity['wickets']?.toString() ?? '0',
            'label': 'Wickets'
          },
        ];
        break;
      default:
        if (recentActivity['distance'] != null) {
          metricsDisplay = 'Distance: ${recentActivity['distance']} km';
          statBlocks = [
            {
              'value': recentActivity['distance']?.toString() ?? '0',
              'label': 'Distance'
            },
          ];
        }
        if (recentActivity['time_taken_seconds'] != null) {
          final totalSeconds =
              int.tryParse(recentActivity['time_taken_seconds']) ?? 0;
          final minutes = totalSeconds ~/ 60;
          final seconds = totalSeconds % 60;
          metricsDisplay += ' | Time: ${minutes}m ${seconds}s';
          statBlocks.add({
            'value': '${minutes}:${seconds.toString().padLeft(2, '0')}',
            'label': 'Time'
          });
        }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _getSportIcon(sportType),
                          color: const Color(0xFFF59E0B),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                            sportType,
                style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF6B7280).withOpacity(0.8),
                            ),
              ),
            ],
          ),
                    ),
                  ],
                ),
                if (metricsDisplay.isNotEmpty) ...[
                  const SizedBox(height: 16),
          Text(
                    metricsDisplay,
            style: const TextStyle(
                      fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
                ],
              ],
            ),
          ),
          if (statBlocks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: statBlocks
                  .map((stat) => _buildStatBlock(
                        value: stat['value']!,
                        label: stat['label']!,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBlock({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
            children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6B7280).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
