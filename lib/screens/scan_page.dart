import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../colors/color.dart';
import '../widgets/bottom_nav.dart';

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
    }
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
                        onPressed: _openGallery,
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
                          onPressed: () {
                            // TODO: implement capture
                          },
                        ),
                      ),

                      // Torch button
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

