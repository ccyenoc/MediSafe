import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../colors/color.dart';
import '../models/medicine.dart';
import '../services/fda_api_service.dart';
import '../services/firestore_service.dart';
import '../services/medicine_matcher_service.dart';
import '../services/ocr_service.dart';
import '../widgets/bottom_nav.dart';
import 'ocr_results_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  XFile? _galleryImage;
  XFile? _capturedImage;
  final OcrService _ocrService = OcrService();
  final MedicineMatcherService _matcherService = MedicineMatcherService();
  final FdaApiService _fdaApiService = FdaApiService();
  final FirestoreService _firestoreService = FirestoreService();

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
      setState(() {
        _galleryImage = image;
        _capturedImage = null;
      });
      await _processImage(image);
    }
  }

  Future<void> _captureImage() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isTakingPicture) return;

    final image = await controller.takePicture();
    setState(() {
      _capturedImage = image;
      _galleryImage = null;
    });
    await _processImage(image);
  }

  Future<List<String>> _loadUserCurrentMedications() async {
    try {
      final snapshot = await _firestoreService.getUserProfile().first;
      final data = snapshot.data() as Map<String, dynamic>?;
      final meds = data?['current_medications'] ?? data?['medications'];
      if (meds is List) {
        return meds.map((item) => item.toString()).toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<void> _processImage(XFile image) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final imageFile = File(image.path);
      final extractedText = await _ocrService.extractTextFromImage(imageFile);
      final words = _ocrService.extractWords(extractedText);

      final correctedChemicalName =
          await _fdaApiService.resolveChemicalNameFromOcr(
        candidates: words,
        fullText: extractedText,
      );

      final searchTerms = correctedChemicalName != null
          ? [correctedChemicalName]
          : words.take(5).toList();

      final candidates = <Medicine>[];
      final seenNames = <String>{};
      for (final term in searchTerms) {
        final results = await _fdaApiService.searchMedicine(term);
        for (final medicine in results) {
          final key = medicine.name.toLowerCase();
          if (seenNames.add(key)) {
            candidates.add(medicine);
          }
        }
      }

      final matched = _matcherService.findMostProbableMedicine(
        extractedText,
        candidates,
      );

      final alternativeMatches = _matcherService
          .findTopMatches(extractedText, candidates, topN: 3)
          .map((item) => item.$1)
          .where((medicine) => matched == null || medicine.name != matched.name)
          .toList();

      final userCurrentMedications = await _loadUserCurrentMedications();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OcrResultsPage(
            extractedText: extractedText,
            matchedMedicine: matched,
            alternativeMedicines: alternativeMatches,
            userCurrentMedications: userCurrentMedications,
            imageFile: imageFile,
            fdaApiService: _fdaApiService,
            firestoreService: _firestoreService,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
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
                    : _capturedImage != null
                        ? Image.file(
                            File(_capturedImage!.path),
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
                          onPressed: () {
                            Navigator.pop(context); // go back to previous page
                          },
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

                // Scanner overlay (center square)
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
                        icon:
                            const Icon(Icons.photo, color: Colors.white, size: 30),
                        onPressed: _isProcessing ? null : _openGallery,
                      ),

                      // Camera button (round)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: AppColors.darkBlue, size: 32),
                          onPressed: _isProcessing ? null : _captureImage,
                        ),
                      ),

                      // Torch button
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
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

