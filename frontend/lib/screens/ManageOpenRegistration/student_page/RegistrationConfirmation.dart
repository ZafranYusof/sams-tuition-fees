// lib/screens/student/RegistrationConfirmation.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RegistrationConfirmation extends StatelessWidget {
  final List<String> codes;
  const RegistrationConfirmation({super.key, required this.codes});

  void _showResult(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registration Success'),
        content: Text('Successfully registered: ${codes.join(", ")}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing...')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showResult(context),
              child: const Text('Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }
}