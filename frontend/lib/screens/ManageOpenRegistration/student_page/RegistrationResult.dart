// lib/screens/student/RegistrationResult.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'RegistrationConfirmation.dart'; // Navigate here to process

class RegistrationResult extends StatelessWidget {
  final List<String> selectedCodes;

  const RegistrationResult({super.key, required this.selectedCodes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Registration')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: selectedCodes.length,
              itemBuilder: (ctx, i) => ListTile(title: Text('Subject: ${selectedCodes[i]}')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), // Back to Home/Dashboard
                    child: const Text('Back To Home'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => RegistrationConfirmation(codes: selectedCodes))
                    ),
                    child: const Text('Confirm'),
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