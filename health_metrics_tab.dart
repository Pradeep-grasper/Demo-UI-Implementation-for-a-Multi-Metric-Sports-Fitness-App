import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class HealthMetricsTab extends StatefulWidget {
  const HealthMetricsTab({Key? key}) : super(key: key);

  @override
  State<HealthMetricsTab> createState() => _HealthMetricsTabState();
}

class _HealthMetricsTabState extends State<HealthMetricsTab> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  DateTime _selectedDateTime = DateTime.now();

  // Latest saved metrics state
  Map<String, dynamic> _latestMetrics = {
    'restHeartRate': null,
    'targetHeartRate': null,
    'maxHeartRate': null,
    'bpSystolic': null,
    'bpDiastolic': null,
    'bpTime': null,
    'temperature': null,
    'bloodOxygen': null,
    'bloodSugar': null,
    'sleepDuration': null,
    'sleepQuality': null,
    'recoveryRate': null,
  };

  // Heart Rate Controllers
  final _restHeartRateController = TextEditingController();
  final _targetHeartRateController = TextEditingController();
  final _maxHeartRateController = TextEditingController();

  // Blood Pressure Controllers
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _bpTimeController = TextEditingController();

  // Other Vitals Controllers
  final _temperatureController = TextEditingController();
  final _bloodOxygenController = TextEditingController();
  final _bloodSugarController = TextEditingController();

  // Sleep Metrics Controllers
  final _sleepDurationController = TextEditingController();
  double _sleepQuality = 7;
  final _recoveryRateController = TextEditingController();

  @override
  void dispose() {
    _restHeartRateController.dispose();
    _targetHeartRateController.dispose();
    _maxHeartRateController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _bpTimeController.dispose();
    _temperatureController.dispose();
    _bloodOxygenController.dispose();
    _bloodSugarController.dispose();
    _sleepDurationController.dispose();
    _recoveryRateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
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

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
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

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveHealthMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update latest metrics
      setState(() {
        _latestMetrics = {
          'restHeartRate': _restHeartRateController.text,
          'targetHeartRate': _targetHeartRateController.text,
          'maxHeartRate': _maxHeartRateController.text,
          'bpSystolic': _bpSystolicController.text,
          'bpDiastolic': _bpDiastolicController.text,
          'bpTime': _selectedDateTime.toIso8601String(),
          'temperature': _temperatureController.text,
          'bloodOxygen': _bloodOxygenController.text,
          'bloodSugar': _bloodSugarController.text,
          'sleepDuration': _sleepDurationController.text,
          'sleepQuality': _sleepQuality.round().toString(),
          'recoveryRate': _recoveryRateController.text,
        };
      });

      await _firestoreService.saveHealthMetrics(
        // Heart Rate
        restHeartRate: double.parse(_restHeartRateController.text),
        targetHeartRate: double.parse(_targetHeartRateController.text),
        maxHeartRate: double.parse(_maxHeartRateController.text),

        // Blood Pressure
        bpSystolic: int.parse(_bpSystolicController.text),
        bpDiastolic: int.parse(_bpDiastolicController.text),
        bpTime: _selectedDateTime.toIso8601String(),

        // Other Vitals
        temperature: double.parse(_temperatureController.text),
        bloodOxygen: double.parse(_bloodOxygenController.text),
        bloodSugar: int.parse(_bloodSugarController.text),

        // Sleep Metrics
        sleepDuration: double.parse(_sleepDurationController.text),
        sleepQuality: _sleepQuality.toInt(),
        recoveryRate: int.parse(_recoveryRateController.text),
      );

      // Clear form
      _formKey.currentState!.reset();
      _restHeartRateController.clear();
      _targetHeartRateController.clear();
      _maxHeartRateController.clear();
      _bpSystolicController.clear();
      _bpDiastolicController.clear();
      _bpTimeController.clear();
      _temperatureController.clear();
      _bloodOxygenController.clear();
      _bloodSugarController.clear();
      _sleepDurationController.clear();
      _recoveryRateController.clear();
      setState(() => _sleepQuality = 7);
      setState(() {
        _selectedDateTime = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health metrics saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving health metrics: $e')),
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
      child: Form(
            key: _formKey,
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text(
              'Health Metrics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            // Health Metrics Overview Section
            Container(
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
                    'HEALTH METRICS OVERVIEW',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Heart Rate Card
                  _buildOverviewCard(
                    title: 'Heart Rate',
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    metrics: [
                      _buildOverviewMetric(
                        label: 'Resting',
                        value: _latestMetrics['restHeartRate'] == null
                            ? '--'
                            : '${_latestMetrics['restHeartRate']} bpm',
                        status: 'Normal',
                        statusColor: const Color(0xFF10B981),
                      ),
                      _buildOverviewMetric(
                        label: 'Target',
                        value: _latestMetrics['targetHeartRate'] == null
                            ? '--'
                            : '${_latestMetrics['targetHeartRate']} bpm',
                        status: 'Set',
                        statusColor: const Color(0xFF3B82F6),
                      ),
                    ],
                ),
                const SizedBox(height: 16),
                  // Blood Pressure Card
                  _buildOverviewCard(
                    title: 'Blood Pressure',
                    icon: Icons.speed,
                    iconColor: Colors.blue,
                    metrics: [
                      _buildOverviewMetric(
                        label: 'Current',
                        value: _latestMetrics['bpSystolic'] == null ||
                                _latestMetrics['bpDiastolic'] == null
                            ? '--'
                            : '${_latestMetrics['bpSystolic']}/${_latestMetrics['bpDiastolic']} mmHg',
                        status: 'Optimal',
                        statusColor: const Color(0xFF10B981),
                      ),
                      _buildOverviewMetric(
                        label: 'Last Updated',
                        value: _latestMetrics['bpTime'] == null
                            ? '--'
                            : DateTime.parse(_latestMetrics['bpTime'])
                                .toLocal()
                                .toString()
                                .split('.')[0],
                        status: 'Recent',
                        statusColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Other Vitals Card
                  _buildOverviewCard(
                    title: 'Other Vitals',
                    icon: Icons.thermostat,
                    iconColor: Colors.orange,
                    metrics: [
                      _buildOverviewMetric(
                        label: 'Temperature',
                        value: _latestMetrics['temperature'] == null
                            ? '--'
                            : '${_latestMetrics['temperature']}°C',
                        status: 'Normal',
                        statusColor: const Color(0xFF10B981),
                      ),
                      _buildOverviewMetric(
                        label: 'Blood Oxygen',
                        value: _latestMetrics['bloodOxygen'] == null
                            ? '--'
                            : '${_latestMetrics['bloodOxygen']}%',
                        status: 'Good',
                        statusColor: const Color(0xFF10B981),
                      ),
                      _buildOverviewMetric(
                        label: 'Blood Sugar',
                        value: _latestMetrics['bloodSugar'] == null
                            ? '--'
                            : '${_latestMetrics['bloodSugar']} mg/dL',
                        status: 'Normal',
                        statusColor: const Color(0xFF10B981),
                      ),
                    ],
                ),
                const SizedBox(height: 16),
                  // Sleep Metrics Card
                  _buildOverviewCard(
                    title: 'Sleep Metrics',
                    icon: Icons.nightlight_round,
                    iconColor: Colors.green,
                    metrics: [
                      _buildOverviewMetric(
                        label: 'Duration',
                        value: _latestMetrics['sleepDuration'] == null
                            ? '--'
                            : '${_latestMetrics['sleepDuration']} hours',
                        status: 'Good',
                        statusColor: const Color(0xFF10B981),
                      ),
                      _buildOverviewMetric(
                        label: 'Quality',
                        value: _latestMetrics['sleepQuality'] == null
                            ? '--'
                            : '${_latestMetrics['sleepQuality']}/10',
                        status: 'Score',
                        statusColor: const Color(0xFF3B82F6),
                      ),
                      _buildOverviewMetric(
                        label: 'Recovery',
                        value: _latestMetrics['recoveryRate'] == null
                            ? '--'
                            : '${_latestMetrics['recoveryRate']}%',
                        status: 'Good',
                        statusColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Heart Rate Section
            _buildMetricCard(
              title: 'Heart Rate',
              icon: Icons.favorite,
              iconColor: Colors.red,
              children: [
                _buildInputField(
                  label: 'Resting Heart Rate',
                  controller: _restHeartRateController,
                  placeholder: 'Enter resting heart rate (bpm)',
                ),
                _buildInputField(
                  label: 'Target Heart Rate',
                  controller: _targetHeartRateController,
                  placeholder: 'Enter target heart rate (bpm)',
                ),
                _buildInputField(
                  label: 'Max Heart Rate',
                  controller: _maxHeartRateController,
                  placeholder: 'Enter max heart rate (bpm)',
                ),
              ],
                ),
                const SizedBox(height: 16),

            // Blood Pressure Section
            _buildMetricCard(
              title: 'Blood Pressure',
              icon: Icons.speed,
              iconColor: Colors.blue,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Systolic',
                        controller: _bpSystolicController,
                        placeholder: 'Enter systolic pressure',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: 'Diastolic',
                        controller: _bpDiastolicController,
                        placeholder: 'Enter diastolic pressure',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Measurement Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3366FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF3366FF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_selectedDateTime.toLocal().toString().split('.')[0]}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
                ),
                const SizedBox(height: 16),

            // Other Vitals Section
            _buildMetricCard(
              title: 'Other Vitals',
              icon: Icons.thermostat,
              iconColor: Colors.orange,
              children: [
                _buildInputField(
                  label: 'Body Temperature (°C)',
                  controller: _temperatureController,
                  placeholder: 'e.g. 36.6',
                  step: 0.1,
                ),
                _buildInputField(
                  label: 'Blood Oxygen (%)',
                  controller: _bloodOxygenController,
                  placeholder: 'e.g. 98',
                  step: 0.1,
                ),
                _buildInputField(
                  label: 'Blood Sugar (mg/dL)',
                  controller: _bloodSugarController,
                  placeholder: 'e.g. 90',
                ),
              ],
                ),
                const SizedBox(height: 16),

            // Sleep Metrics Section
            _buildMetricCard(
              title: 'Sleep Metrics',
              icon: Icons.nightlight_round,
              iconColor: Colors.green,
              children: [
                _buildInputField(
                  label: 'Sleep Duration (hours)',
                  controller: _sleepDurationController,
                  placeholder: 'e.g. 7.5',
                  step: 0.1,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sleep Quality (1-10)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _sleepQuality,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _sleepQuality.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                _sleepQuality = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            _sleepQuality.round().toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildInputField(
                  label: 'Resting Recovery Rate (%)',
                  controller: _recoveryRateController,
                  placeholder: 'e.g. 85',
                ),
              ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveHealthMetrics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Health Metrics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> metrics,
  }) {
    return Container(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...metrics,
        ],
      ),
    );
  }

  Widget _buildOverviewMetric({
    required String label,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }
}
