import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';
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
  final TextEditingController _claimController = TextEditingController();
  String? _selectedFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _claimController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedFileName = picked.name);
    }
  }

  Future<void> _submitClaim() async {
    if (_claimController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supporting claim text.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiService.post('/curriculum/claim', {
        'activityId': widget.activityId,
        'supportingClaim': _claimController.text.trim(),
        'evidence': _selectedFileName ?? '',
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: SAMsTheme.surface,
          title: const Text('Success', style: TextStyle(fontFamily: 'Inter', color: SAMsTheme.ink)),
          content: const Text('Credit claim submitted successfully.', style: TextStyle(fontFamily: 'Inter', color: SAMsTheme.muted)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: SAMsTheme.accent, fontFamily: 'Inter')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Submit Credit Claim'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: SAMsTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── activity name ──
            Text(
              'Activity: ${widget.activityName}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: SAMsTheme.ink,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            // ── supporting claim label ──
            const Text(
              'Supporting Claim',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: SAMsTheme.ink,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            // ── textarea ──
            TextField(
              controller: _claimController,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Inter', color: SAMsTheme.ink),
              decoration: InputDecoration(
                hintText: 'Enter supporting claim...',
                hintStyle: const TextStyle(color: SAMsTheme.muted, fontFamily: 'Inter'),
                filled: true,
                fillColor: SAMsTheme.surface,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: SAMsTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: SAMsTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: SAMsTheme.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ── proof document label ──
            const Text(
              'Proof Document',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: SAMsTheme.ink,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            // ── file status ──
            Text(
              _selectedFileName ?? 'No file selected',
              style: const TextStyle(
                color: SAMsTheme.muted,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 10),
            // ── upload button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Iconsax.document_upload, size: 18),
                label: const Text('Upload Proof'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SAMsTheme.surface,
                  foregroundColor: SAMsTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: SAMsTheme.border),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
            const Spacer(),
            // ── submit button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SAMsTheme.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
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
