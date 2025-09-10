import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedIndex = 2; // Profile is selected by default

  // Basic info
  String _name = '';
  String _phone = '';
  String _email = '';
  String _gender = '';
  DateTime? _birthday;

  // Body metrics
  double _height = 0;
  double _weight = 0;
  double _waistDiameter = 0;
  double _hipDiameter = 0;
  double _shoulderGirth = 0;
  DateTime? _dateOfMeasured;

  // Calculated metrics
  double get _bmi => (_height > 0 && _weight > 0)
      ? _weight / ((_height / 100) * (_height / 100))
      : 0;
  double get _waistToHipRatio => (_hipDiameter > 0 && _waistDiameter > 0)
      ? _waistDiameter / _hipDiameter
      : 0;
  int get _age {
    if (_birthday == null) return 0;
    final today = DateTime.now();
    int age = today.year - _birthday!.year;
    if (today.month < _birthday!.month ||
        (today.month == _birthday!.month && today.day < _birthday!.day)) {
      age--;
    }
    return age;
  }

  double get _bmr {
    if (_gender.isEmpty || _weight <= 0 || _height <= 0 || _age <= 0) return 0;

    if (_gender == 'Male') {
      return 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * _age);
    } else if (_gender == 'Female') {
      return 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * _age);
    } else {
      return 0;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Save basic information
      final basicInfo = {
        'name': _name,
        'phone': _phone,
        'email': _email,
        'gender': _gender,
        'birthday': _birthday?.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Save to users/{userId}/basic_info/profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('basic_info')
          .doc('profile')
          .set(basicInfo, SetOptions(merge: true));

      // Save body metrics
      final bodyMetrics = {
        'height': _height,
        'weight': _weight,
        'waistDiameter': _waistDiameter,
        'hipDiameter': _hipDiameter,
        'shoulderGirth': _shoulderGirth,
        'dateOfMeasured': _dateOfMeasured?.toIso8601String(),
        // Calculated metrics
        'bmi': _bmi,
        'bmiCategory': _getBMICategory(_bmi),
        'waistToHipRatio': _waistToHipRatio,
        'whrCategory': _getWHRCategory(_waistToHipRatio),
        'bmr': _bmr,
        'age': _age,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Save to users/{userId}/body_metrics
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('body_metrics')
          .add(bodyMetrics);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load basic information and body metrics in parallel
      final basicInfoFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('basic_info')
          .doc('profile')
          .get();

      final bodyMetricsFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('body_metrics')
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      // Wait for both futures to complete
      final results = await Future.wait([basicInfoFuture, bodyMetricsFuture]);
      final basicInfoDoc = results[0] as DocumentSnapshot;
      final bodyMetricsSnapshot = results[1] as QuerySnapshot;

      // Update state once with all data
      setState(() {
        // Load basic information
        if (basicInfoDoc.exists) {
          final data = basicInfoDoc.data() as Map<String, dynamic>;
          _name = data['name'] ?? '';
          _phone = data['phone'] ?? '';
          _email = data['email'] ?? '';
          _gender = data['gender'] ?? '';
          _birthday = data['birthday'] != null
              ? DateTime.parse(data['birthday'])
              : null;
        }

        // Load body metrics
        if (bodyMetricsSnapshot.docs.isNotEmpty) {
          final data =
              bodyMetricsSnapshot.docs.first.data() as Map<String, dynamic>;
          _height = (data['height'] ?? 0).toDouble();
          _weight = (data['weight'] ?? 0).toDouble();
          _waistDiameter = (data['waistDiameter'] ?? 0).toDouble();
          _hipDiameter = (data['hipDiameter'] ?? 0).toDouble();
          _shoulderGirth = (data['shoulderGirth'] ?? 0).toDouble();
          _dateOfMeasured = data['dateOfMeasured'] != null
              ? DateTime.parse(data['dateOfMeasured'])
              : null;
        }
      });
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background (same as onboarding)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEAF6F6),
                  Color(0xFFA0D2DB),
                ],
              ),
            ),
          ),
          // Semi-transparent overlay for premium look
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.account_circle,
                              size: 80, color: Colors.grey),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit,
                                color: Colors.grey[700], size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _sectionCard(
                    title: 'Basic information',
                    child: Column(
                      children: [
                        _buildTextField(
                            'Name', _name, (v) => setState(() => _name = v!),
                            validator: _required),
                        const SizedBox(height: 12),
                        _buildTextField('Phone number', _phone,
                            (v) => setState(() => _phone = v!),
                            keyboardType: TextInputType.phone,
                            validator: _required),
                        const SizedBox(height: 12),
                        _buildTextField(
                            'Email', _email, (v) => setState(() => _email = v!),
                            keyboardType: TextInputType.emailAddress,
                            validator: _required),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                            'Gender',
                            _gender,
                            (v) => setState(() => _gender = v!),
                            ['Male', 'Female', 'Other']),
                        const SizedBox(height: 12),
                        _buildDateField('Birthday', _birthday,
                            (date) => setState(() => _birthday = date)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Body Metrics',
                    child: Column(
                      children: [
                        _buildNumberField(
                            'Height (cm)',
                            _height,
                            (v) => setState(
                                () => _height = double.tryParse(v!) ?? 0),
                            validator: _required),
                        const SizedBox(height: 12),
                        _buildNumberField(
                            'Weight (kg)',
                            _weight,
                            (v) => setState(
                                () => _weight = double.tryParse(v!) ?? 0),
                            validator: _required),
                        const SizedBox(height: 12),
                        _buildNumberField(
                            'Waist Diameter (cm)',
                            _waistDiameter,
                            (v) => setState(() =>
                                _waistDiameter = double.tryParse(v!) ?? 0)),
                        const SizedBox(height: 12),
                        _buildNumberField(
                            'Hip Diameter (cm)',
                            _hipDiameter,
                            (v) => setState(
                                () => _hipDiameter = double.tryParse(v!) ?? 0)),
                        const SizedBox(height: 12),
                        _buildNumberField(
                            'Shoulder Girth (cm)',
                            _shoulderGirth,
                            (v) => setState(() =>
                                _shoulderGirth = double.tryParse(v!) ?? 0)),
                        const SizedBox(height: 12),
                        _buildDateField('Date of Measurement', _dateOfMeasured,
                            (date) => setState(() => _dateOfMeasured = date)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Calculated Metrics',
                    child: Column(
                      children: [
                        _buildMetricCard(
                          'Body Mass Index (BMI)',
                          _bmi > 0 ? _bmi.toStringAsFixed(1) : '-',
                          _getBMICategory(_bmi),
                          Icons.monitor_weight_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          'Waist-to-Hip Ratio',
                          _waistToHipRatio > 0
                              ? _waistToHipRatio.toStringAsFixed(2)
                              : '-',
                          _getWHRCategory(_waistToHipRatio),
                          Icons.straighten,
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          'Basal Metabolic Rate (BMR)',
                          _bmr > 0
                              ? '${_bmr.toStringAsFixed(0)} kcal/day'
                              : '-',
                          null,
                          Icons.local_fire_department_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          'Age',
                          _age > 0 ? '$_age years' : '-',
                          null,
                          Icons.cake_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3366FF), Color(0xFF00C6AE)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 1.1),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // Save profile data
                            await _saveProfileData();

                            // Hide loading indicator
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('Update profile'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex == 2 ? 1 : _selectedIndex,
        selectedItemColor: const Color(0xFF3366FF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      color: Colors.white.withOpacity(0.95),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF3366FF))),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, String? category, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3366FF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3366FF),
            ),
          ),
          if (category != null && category.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getCategoryColor(category).withOpacity(0.3),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: _getCategoryColor(category),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String value, ValueChanged<String?> onChanged,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      initialValue: value,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField(String label, String value,
      ValueChanged<String> onChanged, List<String> options) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : null,
      items: options
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v ?? ''),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      validator: _required,
    );
  }

  Widget _buildDateField(
      String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF3366FF),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
              text: value != null
                  ? DateFormat('dd / MM / yyyy').format(value)
                  : ''),
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.black45),
          ),
          validator: _required,
        ),
      ),
    );
  }

  Widget _buildNumberField(
      String label, double value, ValueChanged<String?> onChanged,
      {String? Function(String?)? validator}) {
    return TextFormField(
      initialValue: value > 0 ? value.toString() : '',
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      onChanged: onChanged,
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  String _getBMICategory(double bmi) {
    if (bmi <= 0) return '';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _getWHRCategory(double whr) {
    if (whr <= 0) return '';
    if (_gender == 'Male') {
      if (whr < 0.9) return 'Low risk';
      if (whr < 1.0) return 'Moderate risk';
      return 'High risk';
    } else {
      if (whr < 0.8) return 'Low risk';
      if (whr < 0.85) return 'Moderate risk';
      return 'High risk';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
      case 'high risk':
        return Colors.red;
      case 'normal weight':
      case 'low risk':
        return Colors.green;
      case 'overweight':
      case 'moderate risk':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
