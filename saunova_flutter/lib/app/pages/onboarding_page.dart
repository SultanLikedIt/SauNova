import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _gender;
  final List<String> _selectedGoals = [];
  bool _loading = false;

  final List<Map<String, String>> goals = [
    {'id': 'stress_reduction', 'label': 'Stress Reduction'},
    {'id': 'cardiovascular_health', 'label': 'Cardiovascular Health'},
    {'id': 'muscle_recovery', 'label': 'Muscle Recovery'},
    {'id': 'improving_sleep_quality', 'label': 'Improving Sleep Quality'},
    {'id': 'longevity', 'label': 'Longevity'},
    {'id': 'cold_recovery', 'label': 'Cold Recovery'},
  ];

  final List<String> genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  void _toggleGoal(String id) {
    setState(() {
      if (_selectedGoals.contains(id)) {
        _selectedGoals.remove(id);
      } else {
        _selectedGoals.add(id);
      }
    });
  }

  bool _validateForm() {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (age == null || age < 1 || age > 150) {
      _showError('Please enter a valid age');
      return false;
    }
    if (_gender == null || _gender!.isEmpty) {
      _showError('Please select your gender');
      return false;
    }
    if (height == null || height <= 0) {
      _showError('Please enter a valid height (in cm)');
      return false;
    }
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight (in kg)');
      return false;
    }
    if (_selectedGoals.isEmpty) {
      _showError('Please select at least one goal');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() => _loading = true);
    //send the ids of the goals

    final result = await ref
        .read(coreProvider.notifier)
        .saveUserProfile(
          int.parse(_ageController.text),
          _gender!,
          int.parse(_heightController.text),
          int.parse(_weightController.text),
          _selectedGoals,
        );

    setState(() => _loading = false);

    if (!mounted) return;
    if (result) {
      Navigator.pushReplacementNamed(context, '/root');
    } else {
      _showError('Failed to save profile. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome to saunova!',
                      style: textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Let's set up your profile to personalize your sauna experience",
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacityValue(
                          0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Age
              _buildLabel('Age'),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(hintText: 'Enter your age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Gender
              _buildLabel('Gender'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: genders.map((g) {
                  final selected = _gender == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (_) => setState(() => _gender = g),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Height
              _buildLabel('Height (cm)'),
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                  hintText: 'Enter your height in centimeters',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),

              // Weight
              _buildLabel('Weight (kg)'),
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  hintText: 'Enter your weight in kilograms',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),

              // Goals
              _buildLabel('Long-term Goals'),
              Text(
                'Select all that apply (at least one required)',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacityValue(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: goals.map((goal) {
                  final selected = _selectedGoals.contains(goal['id']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _toggleGoal(goal['id']!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : AppColors.border,
                          ),
                          color: selected
                              ? theme.colorScheme.primary.withOpacityValue(0.1)
                              : theme.colorScheme.surface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              goal['label']!,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Complete Setup'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
