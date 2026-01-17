import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/exam_models.dart';
import '../widgets/role_card_widget.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;

  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  String _fullName = '';
  String _role = 'teacher';
  String? _institution;
  String? _designation;
  String? _childrenNames;

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final profile = UserProfile(
      id: widget.userId,
      fullName: _fullName,
      role: _role,
      institutionName: _institution,
      designation: _designation,
      childrenNames: _childrenNames,
    );

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.createProfile(profile);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create profile'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
                const SizedBox(height: 32),
                Text(_currentStep == 0 ? "Let's Get Started" : "Almost Done", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 0 ? "We just need a few basic details" : "Tell us a bit more about yourself",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                Expanded(child: _currentStep == 0 ? _buildStep1() : _buildStep2()),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep == 0) {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() => _currentStep = 1);
                        }
                      } else {
                        _complete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentStep == 0 ? 'Continue' : 'Complete Setup',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          onSaved: (value) => _fullName = value ?? '',
        ),
        const SizedBox(height: 24),
        const Text('I am a...', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RoleCard(title: 'Teacher', icon: Icons.school, isSelected: _role == 'teacher', onTap: () => setState(() => _role = 'teacher')),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: RoleCard(
                title: 'Parent',
                icon: Icons.family_restroom,
                isSelected: _role == 'parent',
                onTap: () => setState(() => _role = 'parent'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    if (_role == 'teacher') {
      return Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Institution Name', border: OutlineInputBorder()),
            onSaved: (value) => _institution = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()),
            onSaved: (value) => _designation = value,
          ),
        ],
      );
    } else {
      return TextFormField(
        decoration: const InputDecoration(labelText: "Children's Names (comma separated)", border: OutlineInputBorder()),
        onSaved: (value) => _childrenNames = value,
      );
    }
  }
}
