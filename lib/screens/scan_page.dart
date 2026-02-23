import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../colors/color.dart';
import '../services/ocr_service.dart';
import '../services/gemini_service.dart';
import '../widgets/bottom_nav.dart';
import 'medicine_information_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  XFile? _galleryImage;
  bool _isProcessing = false;

  final _ocrService = OcrService();
  final _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    _isFlashOn = !_isFlashOn;
    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _openGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _galleryImage = image);
      await _processImage(image.path);
    }
  }

  /// Core pipeline: OCR → Gemini → Navigate to result page
  Future<void> _processImage(String imagePath) async {
    setState(() => _isProcessing = true);
    try {
      // 1. On-device OCR via ML Kit
      final ocrText = await _ocrService.extractText(imagePath);

      print("========== RAW OCR TEXT START ==========\n$ocrText\n========== RAW OCR TEXT END ==========");
      if (ocrText.trim().isEmpty) {
        _showError('No text found. Make sure the medicine name/label is clearly visible and well-lit.');
        return;
      }

      // 2. Identify medicine via Gemini (with user profile context)
      final medicine = await _geminiService.identifyMedicine(ocrText);

      // 3. Navigate to result page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineInfoPage(medicine: medicine),
          ),
        );
      }
    } catch (e) {
      _showError('Could not identify medicine: ${e.toString().substring(0, e.toString().length > 120 ? 120 : e.toString().length)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final photo = await _controller!.takePicture();
    await _processImage(photo.path);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MedicalBottomNav(),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Camera or gallery background
                _galleryImage != null
                    ? Image.file(
                        File(_galleryImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.previewSize!.height,
                            height: _controller!.value.previewSize!.width,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),

                // Top AppBar
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 80,
                    color: AppColors.darkBlue,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Scan Medicine',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scanner overlay box
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Processing overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Identifying medicine...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      IconButton(
                        icon: const Icon(Icons.photo, color: Colors.white, size: 30),
                        onPressed: _isProcessing ? null : _openGallery,
                      ),

                      // Capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _capturePhoto,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _isProcessing ? Colors.grey : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: _isProcessing ? Colors.white : AppColors.darkBlue,
                            size: 32,
                          ),
                        ),
                      ),

                      // Flash button
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _isProcessing ? null : _toggleFlash,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
