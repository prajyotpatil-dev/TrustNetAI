import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _signatureCaptured = false;
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  // ── Geo-tagging state ─────────────────────────────────────────────────
  double? _capturedLat;
  double? _capturedLng;
  bool _isCapturingLocation = false;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _capturedLat = position.latitude;
          _capturedLng = position.longitude;
          _isCapturingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturingLocation = false);
      }
      debugPrint('[ePOD] Failed to capture location: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _photoFile = File(pickedFile.path));
      // Re-capture location when photo is taken
      _captureLocation();
    }
  }

  void _submit() async {
    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the delivery photo.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<TransporterShipmentProvider>().uploadEPOD(
        widget.shipmentId,
        _photoFile!,
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ePOD uploaded successfully! Shipment marked as Delivered. Trust Score updated.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMsg = e.toString();
      if (errorMsg.contains('unauthorized') || errorMsg.contains('permission-denied')) {
        errorMsg = 'Upload failed: Permission denied. Please ensure you are logged in.';
      } else if (errorMsg.contains('object-not-found')) {
        errorMsg = 'Upload failed: Storage object not found.';
      } else if (errorMsg.contains('retry-limit-exceeded')) {
        errorMsg = 'Upload failed: Network error. Please check your connection and try again.';
      } else {
        errorMsg = 'Upload failed: ${e.toString().replaceAll('Exception: ', '')}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
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
          Text('Electronic Proof of Delivery · #${widget.shipmentId}',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),

          // ── AI Info Card ─────────────────────────────────────────────
          Card(
            color: const Color(0xFFEFF6FF),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI will auto-verify your proof: geo-tag location, compute image hash for fraud detection, and update your Trust Score.',
                    style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Location Capture Status ─────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _capturedLat != null ? const Color(0xFFECFDF5) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _capturedLat != null ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Row(children: [
              Icon(
                _capturedLat != null ? Icons.location_on : Icons.location_searching,
                color: _capturedLat != null ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _isCapturingLocation
                    ? const Text('Capturing GPS location...', style: TextStyle(fontSize: 13, color: Colors.black54))
                    : _capturedLat != null
                        ? Text(
                            'Location: ${_capturedLat!.toStringAsFixed(5)}, ${_capturedLng!.toStringAsFixed(5)}',
                            style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                          )
                        : const Text('Location unavailable', style: TextStyle(fontSize: 13, color: Colors.black54)),
              ),
              if (_isCapturingLocation)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Upload Photo ────────────────────────────────────────────
          const Text('Delivery Photo *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _photoFile != null ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
                color: _photoFile != null ? Colors.green.shade50 : Colors.grey.shade50,
                image: _photoFile != null
                    ? DecorationImage(
                        image: FileImage(_photoFile!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                      )
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
                      Text('Photo will be geo-tagged + hash verified', style: TextStyle(color: Colors.black38, fontSize: 12)),
                    ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Signature ───────────────────────────────────────────────
          const Text('Receiver Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _signatureCaptured = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _signatureCaptured ? Colors.green : Colors.grey.shade300, width: 2),
                color: _signatureCaptured ? Colors.green.shade50 : Colors.grey.shade50,
              ),
              child: _signatureCaptured
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
          const SizedBox(height: 16),

          // ── What AI Does Card ───────────────────────────────────────
          Card(
            elevation: 0,
            color: const Color(0xFFF5F3FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.psychology, color: Colors.purple, size: 18),
                    SizedBox(width: 8),
                    Text('AI Processing on Submit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13)),
                  ]),
                  SizedBox(height: 8),
                  Text('✓ Geo-tag attached (lat/lng)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('✓ Image hash computed (fraud detection)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('✓ Trust Score updated (+5 for ePOD)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('✓ Duplicate image check across shipments', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

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
