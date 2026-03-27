import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_layout.dart';
import '../../providers/transporter_shipment_provider.dart';
import '../../providers/user_provider.dart';

class UploadEPODScreen extends StatefulWidget {
  final String shipmentId;
  const UploadEPODScreen({super.key, required this.shipmentId});

  @override
  State<UploadEPODScreen> createState() => _UploadEPODScreenState();
}

class _UploadEPODScreenState extends State<UploadEPODScreen> {
  File? _photoFile;
  bool _signatureCapured = false;
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _photoFile = File(pickedFile.path));
    }
  }

  void _submit() async {
    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload the delivery photo.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<TransporterShipmentProvider>().uploadEPOD(widget.shipmentId, _photoFile!, remarks: _remarksController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ePOD uploaded successfully! Shipment marked as Delivered.'), backgroundColor: Colors.green),
      );
      final role = context.read<UserProvider>().user?.role ?? 'transporter';
      context.go(role == 'business' ? '/business/dashboard' : '/transporter/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      role: 'transporter',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Upload ePOD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Electronic Proof of Delivery · #${widget.shipmentId}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          // Info card
          Card(
            color: const Color(0xFFEFF6FF),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(child: const Text('Upload a geo-tagged photo and receiver signature to complete delivery and boost your Trust Score.', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13))),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          // Upload Photo
          const Text('Delivery Photo *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _photoFile != null ? Colors.green : Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                color: _photoFile != null ? Colors.green.shade50 : Colors.grey.shade50,
                image: _photoFile != null
                    ? DecorationImage(image: FileImage(_photoFile!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
                    : null,
              ),
              child: _photoFile != null
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text('Photo Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Tap to retake', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ])
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.camera_alt, color: Colors.black38, size: 40),
                      SizedBox(height: 8),
                      Text('Tap to take photo', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      Text('Photo will be geo-tagged automatically', style: TextStyle(color: Colors.black38, fontSize: 12)),
                    ]),
            ),
          ),
          const SizedBox(height: 20),
          // Signature
          const Text('Receiver Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _signatureCapured = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _signatureCapured ? Colors.green : Colors.grey.shade300, width: 2),
                color: _signatureCapured ? Colors.green.shade50 : Colors.grey.shade50,
              ),
              child: _signatureCapured
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.gesture, color: Colors.green),
                      Text('Signature Captured', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ]))
                  : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.gesture, color: Colors.black38),
                      Text('Tap to capture signature', style: TextStyle(color: Colors.black54)),
                    ])),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Remarks', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 2,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: 'Optional delivery notes...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload, color: Colors.white),
            label: const Text('Submit ePOD & Complete Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    );
  }
}
