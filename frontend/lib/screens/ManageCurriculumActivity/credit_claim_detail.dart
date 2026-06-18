import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CreditClaimDetailScreen extends StatefulWidget {
  final String activityId;
  final String activityName;

  const CreditClaimDetailScreen({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  State<CreditClaimDetailScreen> createState() =>
      _CreditClaimDetailScreenState();
}

class _CreditClaimDetailScreenState extends State<CreditClaimDetailScreen> {
  final TextEditingController claimController = TextEditingController();

  String? selectedFileName;
  bool isSubmitting = false;

  @override
  void dispose() {
    claimController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedFileName = picked.name;
      });
    }
  }

  Future<void> _submitClaim() async {
    if (claimController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supporting claim text.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ApiService.post('/curriculum/claim', {
        'activityId': widget.activityId,
        'supportingClaim': claimController.text.trim(),
        'evidence': selectedFileName ?? '',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Credit claim submitted successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to claims list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Credit Claim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity: ${widget.activityName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Supporting Claim',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: claimController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter supporting claim...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Proof Document',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(selectedFileName ?? 'No file selected'),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Iconsax.document_upload),
              label: const Text('Upload Proof'),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitClaim,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Claim'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}