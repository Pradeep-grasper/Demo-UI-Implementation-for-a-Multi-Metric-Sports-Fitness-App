import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class WorkoutSessionTab extends StatefulWidget {
  const WorkoutSessionTab({super.key});

  @override
  State<WorkoutSessionTab> createState() => _WorkoutSessionTabState();
}

class _WorkoutSessionTabState extends State<WorkoutSessionTab> {
  final _formKey = GlobalKey<FormState>();
  int _exerciseCount = 0;
  DateTime? _startTime;
  DateTime? _endTime;
  String _selectedFeeling = 'great';
  bool _isCompleted = false;
  final Map<int, double> _exercisePerformance = {};
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _workoutNameController = TextEditingController();
  final TextEditingController _assignedTimeController = TextEditingController();
  final TextEditingController _actualTimeController = TextEditingController();

  // Dropdown value variables for time units
  String? _assignedTimeUnit = 'minutes';
  String? _actualTimeUnit = 'minutes';

  // Add this variable for dropdown
  String? _selectedSessionOfDay;

  @override
  void dispose() {
    _workoutNameController.dispose();
    _assignedTimeController.dispose();
    _actualTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workout Session',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your workout details and exercises',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              // Workout details card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextFormField(
                        label: 'Workout Name',
                        controller: _workoutNameController,
                        hintText: 'e.g. Upper Body Strength',
                      ),
                      const SizedBox(height: 16),
                      // Session of day dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session of Day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSessionOfDay,
                            items: const ['Morning', 'Afternoon', 'Evening']
                                .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSessionOfDay = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Select session time',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF4F46E5), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an option';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Time inputs
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeInputField(
                              label: 'Assigned Time',
                              timeController: _assignedTimeController,
                              unitValue: _assignedTimeUnit,
                              onUnitChanged: (value) {
                                setState(() {
                                  _assignedTimeUnit = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeInputField(
                              label: 'Actual Time',
                              timeController: _actualTimeController,
                              unitValue: _actualTimeUnit,
                              onUnitChanged: (value) {
                                setState(() {
                                  _actualTimeUnit = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // How do you feel section
                      const Text(
                        'How Do You Feel?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeelingOption('😫', 'Terrible', 'terrible'),
                          _buildFeelingOption('😔', 'Bad', 'bad'),
                          _buildFeelingOption('😐', 'Okay', 'okay'),
                          _buildFeelingOption('😊', 'Good', 'good'),
                          _buildFeelingOption('🤩', 'Great', 'great'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Completed checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isCompleted,
                            onChanged: (value) {
                              setState(() {
                                _isCompleted = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Text(
                            'Mark as completed',
                            style: TextStyle(color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Exercises section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Training Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white),
                    label: const Text(
                      'Add Exercise',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Exercise list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exerciseCount,
                itemBuilder: (context, index) {
                  return _buildExerciseCard(index + 1);
                },
              ),
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.save_alt, color: Colors.white),
                  label: _isLoading
                      ? const Text(
                          'Saving...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Text(
                          'Save Workout',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: isMultiline ? 3 : 1,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFeelingOption(String emoji, String label, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeeling = value;
        });
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _selectedFeeling == value
                  ? const Color(0xFFE0E7FF)
                  : Colors.transparent,
              border: Border.all(
                color: _selectedFeeling == value
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInputField({
    required String label,
    required TextEditingController timeController,
    required String? unitValue,
    required ValueChanged<String?> onUnitChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: timeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '45',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: unitValue,
                items: const ['minutes', 'hours']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: onUnitChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                dropdownColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseCard(int exerciseNumber) {
    _exercisePerformance.putIfAbsent(exerciseNumber, () => 75.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercise #$exerciseNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _exerciseCount--;
                      _exercisePerformance.remove(exerciseNumber);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Exercise name and category
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    label: 'Exercise Name',
                    controller: TextEditingController(),
                    hintText: 'e.g. Bench Press',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: 'Strength',
                          items: const [
                            'Strength',
                            'Cardio',
                            'Flexibility',
                            'Balance',
                            'Core'
                          ]
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {},
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sets, reps, weight
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    label: 'Sets',
                    controller: TextEditingController(),
                    hintText: 'e.g. 3',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    label: 'Reps',
                    controller: TextEditingController(),
                    hintText: 'e.g. 12',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    label: 'Weight (kg)',
                    controller: TextEditingController(),
                    hintText: 'e.g. 50',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rest times
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    label: 'Assigned Rest (sec)',
                    controller: TextEditingController(),
                    hintText: 'e.g. 60',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    label: 'Actual Rest (sec)',
                    controller: TextEditingController(),
                    hintText: 'e.g. 75',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Performance slider
            const Text(
              'Performance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _exercisePerformance[exerciseNumber]!,
              min: 0,
              max: 100,
              divisions: 10,
              label: '${_exercisePerformance[exerciseNumber]!.toInt()}%',
              onChanged: (value) {
                setState(() {
                  _exercisePerformance[exerciseNumber] = value;
                });
              },
              activeColor:
                  _getPerformanceColor(_exercisePerformance[exerciseNumber]!),
              inactiveColor: const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0%', style: TextStyle(fontSize: 12)),
                Text('100%', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(double value) {
    if (value < 30) return Colors.red;
    if (value < 70) return Colors.orange;
    return Colors.green;
  }

  Future<void> _selectDateTime(BuildContext context,
      {required bool isStartTime}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4F46E5),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        final DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStartTime) {
            _startTime = pickedDateTime;
          } else {
            _endTime = pickedDateTime;
          }
        });
      }
    }
  }

  void _addExercise() {
    setState(() {
      _exerciseCount++;
    });
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.saveWorkout(
        name: _workoutNameController.text,
        type: _selectedSessionOfDay ?? '',
        distance: double.parse(_assignedTimeController.text),
        duration: double.parse(_actualTimeController.text),
        plannedPace: _assignedTimeUnit ?? 'minutes',
        actualPace: _actualTimeUnit ?? 'minutes',
        heartRate: 0.0, // Assuming no heart rate data
        calories: 0, // Assuming no calories data
        weight: 0.0, // Assuming no weight data
        bmi: 0.0, // Assuming no BMI data
      );

      // Clear form
      _formKey.currentState!.reset();
      _workoutNameController.clear();
      _selectedSessionOfDay = null;
      _assignedTimeController.clear();
      _actualTimeController.clear();
      _assignedTimeUnit = 'minutes';
      _actualTimeUnit = 'minutes';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
