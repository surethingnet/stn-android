import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firebase_service.dart';

class AddDeviceScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const AddDeviceScreen({
    Key? key,
    required this.firebaseService,
  }) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _macController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _macController.dispose();
    super.dispose();
  }

  /// Request camera permission and start barcode scanner if granted
  Future<void> _startScan() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      _openScannerOverlay();
    } else {
      _showPermissionDeniedWarning();
    }
  }

  /// Shows a clean bottom sheet containing the camera view
  void _openScannerOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Scanner Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan Device Barcode / MAC',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Camera View
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final String? code = barcode.rawValue;
                            if (code != null && code.isNotEmpty) {
                              setState(() {
                                _macController.text = code;
                              });
                              Navigator.pop(context); // Close sheet
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Scanned MAC: $code'),
                                  backgroundColor: const Color(0xFF34C759),
                                ),
                              );
                              break;
                            }
                          }
                        },
                      ),
                      // Target Scanner overlay box
                      Container(
                        width: 250,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF34C759), width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Align a barcode or QR code showing the MAC address inside the target frame.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionDeniedWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.black),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Camera permission denied. You can still type the MAC address manually.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFFF9500),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.firebaseService.addDevice(
        _nameController.text.trim(),
        _modelController.text.trim(),
        _macController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device added to inventory'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.pop(context); // Go back to Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save device: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Add New Device for Audit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the device metadata manually or scan the physical barcode/QR sticker on your hardware.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),

            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Device Name',
              hint: 'e.g. Living Room Router, My Pixel 9',
              validator: (val) => val == null || val.trim().isEmpty ? 'Device name is required' : null,
            ),
            const SizedBox(height: 20),

            // Model Field
            _buildTextField(
              controller: _modelController,
              label: 'Model / Brand',
              hint: 'e.g. Netgear Nighthawk, Google Pixel',
              validator: (val) => val == null || val.trim().isEmpty ? 'Model details are required' : null,
            ),
            const SizedBox(height: 20),

            // MAC Address Field with Scan Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _macController,
                    label: 'MAC Address',
                    hint: 'e.g. AA:BB:CC:11:22:33',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'MAC Address is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 26.0), // Align with text field input
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF34C759)),
                      onPressed: _startScan,
                      tooltip: 'Scan Barcode',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Submit Button
            ElevatedButton(
              onPressed: _isSaving ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Save & Sync Device',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF34C759)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF3B30)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF3B30)),
            ),
          ),
        ),
      ],
    );
  }
}
