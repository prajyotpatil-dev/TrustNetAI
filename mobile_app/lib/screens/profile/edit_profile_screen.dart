import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await context.read<FirebaseService>().get('users', user.uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _nameController.text = data?['name'] ?? user.displayName ?? '';
          _phoneController.text = data?['phone'] ?? user.phoneNumber ?? '';
          _gstinController.text = data?['gstin'] ?? '';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final dataToUpdate = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gstin': _gstinController.text.trim(),
        };
        await context.read<FirebaseService>().set('users', user.uid, dataToUpdate);
        await user.updateDisplayName(_nameController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.camera_alt, size: 32, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildField('Full Name', Icons.person, _nameController),
                  const SizedBox(height: 16),
                  _buildField('Phone Number', Icons.phone, _phoneController),
                  const SizedBox(height: 16),
                  if (_userData?['role'] == 'business') ...[
                    _buildField('GSTIN', Icons.description, _gstinController),
                    const SizedBox(height: 16),
                  ],
                  // Email is read-only usually because changing it requires verification
                  _buildField('Email', Icons.email, TextEditingController(text: FirebaseAuth.instance.currentUser?.email ?? ''), readOnly: true),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black45),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
        ),
      ],
    );
  }
}
