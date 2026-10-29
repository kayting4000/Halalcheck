import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/barcode_service.dart';
import '../services/halal_engine.dart';
import '../services/blockchain_service.dart';
import '../models/halal_location.dart';
import '../widgets/app_theme.dart';

enum _ScanMode { ingredient, barcode }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isAnalyzing = false;
  bool _isFlashOn = false;
  AnalysisResult? _result;
  String? _error;
  String _status = 'Initializing Scanner...';
  _ScanMode _mode = _ScanMode.ingredient;
  final MobileScannerController _barcodeController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _barcodeHandled = false;
  BlockchainVerificationResult? _blockchainResult;

  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
    _initCamera();
    _initBlockchain();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _error = 'Camera permission denied');
      return;
    }
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() => _error = 'No cameras available on this device');
      return;
    }
    _cameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    if (_cameraIndex < 0) _cameraIndex = 0;
    await _startCamera();
  }

  Future<void> _startCamera() async {
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    await _controller?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
    setState(() => _isFlashOn = false);
  }

  Future<void> _toggleFlash() async {
    try {
      if (_mode == _ScanMode.ingredient) {
        if (_controller == null || !_controller!.value.isInitialized) return;
        final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _controller!.setFlashMode(newMode);
      } else {
        await _barcodeController.toggleTorch();
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _error = null;
      _status = 'Reading Ingredients...';
    });

    try {
      final file = await _controller!.takePicture();
      await _controller?.pausePreview();
      await _analyzeImageFile(file.path);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      await _controller?.resumePreview();
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _analyzeImageFile(String path) async {
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _error = null;
      _status = 'Extracting Text (On-Device OCR)...';
    });
    try {
      final text = await OcrService.readText(path);
      if (mounted) setState(() => _status = 'Checking Halal Rules...');
      final result = HalalEngine.analyze(text);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      await _controller?.resumePreview();
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (_mode == _ScanMode.ingredient) {
        await _analyzeImageFile(image.path);
      } else {
        setState(() {
          _isAnalyzing = true;
          _status = 'Decoding Barcode from Photo...';
        });
        final capture = await _barcodeController.analyzeImage(image.path);
        if (capture != null && capture.barcodes.isNotEmpty) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            await _handleBarcode(code);
            return;
          }
        }
        setState(() {
          _isAnalyzing = false;
          _error = 'No barcode detected in selected image. Try another photo or enter manually.';
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = 'Failed to process image: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _handleBarcode(String barcode) async {
    if (_barcodeHandled) return;
    _barcodeHandled = true;
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _error = null;
      _blockchainResult = null;
      _status = 'Looking up Product in Database...';
    });
    try {
      final result = await BarcodeService.lookupBarcode(barcode);
      if (mounted) setState(() => _result = result);
      // Check on-chain halal certificate after product lookup
      if (mounted) {
        setState(() {
          _status = 'Verifying On-Chain Certificate...';
        });
        _blockchainResult = await BlockchainService.verifyCertificateByBarcode(
          barcode,
        );
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _barcodeHandled = false;
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// Initialize blockchain service on first scan.
  Future<void> _initBlockchain() async {
    await BlockchainService.init();
  }

  void _showManualBarcodeDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ENTER BARCODE MANUALLY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 16,
                  fontFamily: 'Philosopher',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Type the 8, 12, or 13-digit EAN/UPC barcode printed on the packaging.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 3),
                decoration: InputDecoration(
                  hintText: 'e.g. 5449000000996',
                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 2),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.magentaLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.magenta, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magenta,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final code = controller.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.pop(ctx);
                    _handleBarcode(code);
                  }
                },
                child: const Text(
                  'LOOKUP PRODUCT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApiInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.magentaLight),
            SizedBox(width: 10),
            Text(
              'HALAL DATABASES & APIS',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How This App Verifies Products:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 12),
              _ApiItem(
                title: 'Open Food Facts API',
                desc: 'Free, global open database with ~3M+ food products. Fetches product ingredients and accredited halal tags by barcode.',
                badge: 'Active Live',
              ),
              SizedBox(height: 12),
              _ApiItem(
                title: 'Offline Halal Engine (On-Device)',
                desc: 'Deterministic rules database parsing hundreds of E-numbers, emulsifiers, gelatin, animal fats, and alcohol markers without internet.',
                badge: 'Offline Active',
              ),
              SizedBox(height: 12),
              _ApiItem(
                title: 'Global Certification Standards',
                desc: 'Recognizes official certification labels including JAKIM (Malaysia), BPJPH (Indonesia), MUI, and European Halal authorities.',
                badge: 'Verified',
              ),
              SizedBox(height: 12),
              _ApiItem(
                title: 'On-Chain Halal Registry (Phase 2)',
                desc: 'Immutable certificate registry on Polygon Amoy testnet. Tamper-proof verification with "Blockchain Verified" badge.',
                badge: 'Read-Only',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT', style: TextStyle(color: AppColors.magentaLight, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _setMode(_ScanMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _result = null;
      _error = null;
      _barcodeHandled = false;
      _isFlashOn = false;
    });
    if (mode == _ScanMode.barcode) {
      _controller?.dispose().then((_) {
        if (mounted) setState(() => _controller = null);
      });
    } else {
      if (_controller == null) _startCamera();
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
      _barcodeHandled = false;
      _blockchainResult = null;
    });
    _controller?.resumePreview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _controller?.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isBarcode = _mode == _ScanMode.barcode;

    // Viewfinder dimensions: Box (Square) for Ingredients vs Rectangle for Barcode
    final boxWidth = (screenSize.width * (isBarcode ? 0.86 : 0.74)).clamp(230.0, isBarcode ? 350.0 : 300.0);
    final boxHeight = isBarcode ? 140.0 : boxWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_mode == _ScanMode.ingredient)
            if (_controller != null && _controller!.value.isInitialized)
              Positioned.fill(child: CameraPreview(_controller!))
            else
              const Center(child: CircularProgressIndicator(color: AppColors.magenta))
          else
            Positioned.fill(
              child: MobileScanner(
                controller: _barcodeController,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final value = barcodes.first.rawValue;
                  if (value != null && value.isNotEmpty) {
                    _handleBarcode(value);
                  }
                },
              ),
            ),

          // Top Mode Switcher Bar
          if (_result == null && !_isAnalyzing)
            Positioned(
              top: 52,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  _ControlButton(
                    icon: Icons.info_outline_rounded,
                    onTap: _showApiInfoDialog,
                    tooltip: 'Halal APIs & Databases',
                  ),
                  const Spacer(),
                  _ModeSwitcher(mode: _mode, onChanged: _setMode),
                  const Spacer(),
                  _ControlButton(
                    icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    onTap: _toggleFlash,
                    active: _isFlashOn,
                    tooltip: 'Toggle Flashlight',
                  ),
                ],
              ),
            ),

          // Viewfinder reticle (Square for ingredient, Rectangle for barcode)
          if (!_isAnalyzing && _result == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.magenta.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(isBarcode ? 20 : 32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.magenta.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Beam
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _laserAnimation.value * (boxHeight - 6),
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.magentaLight.withValues(alpha: 0.8),
                                      Colors.white,
                                      AppColors.magentaLight.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.magenta.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Corner brackets
                        const _Corner(top: true, left: true),
                        const _Corner(top: true, left: false),
                        const _Corner(top: false, left: true),
                        const _Corner(top: false, left: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(_mode),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _mode == _ScanMode.ingredient
                            ? 'Align ingredient list inside the box'
                            : 'Align product barcode inside the rectangle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Control Bar (Capture, Gallery, Manual Input)
          if (_result == null && !_isAnalyzing)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Pick Button
                  _BottomActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: _pickFromGallery,
                  ),

                  // Center Trigger Button
                  if (_mode == _ScanMode.ingredient)
                    GestureDetector(
                      onTap: _capture,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: AppTheme.magentaGlow(radius: 36),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    )
                  else
                    // Barcode Mode: Manual Barcode Entry Button
                    _BottomActionButton(
                      icon: Icons.keyboard_rounded,
                      label: 'Type Barcode',
                      onTap: _showManualBarcodeDialog,
                      isPrimary: true,
                    ),

                  // Camera Switch Button (or flip)
                  _BottomActionButton(
                    icon: Icons.flip_camera_android_rounded,
                    label: 'Flip',
                    onTap: _toggleCamera,
                  ),
                ],
              ),
            ),

          // Analyzing progress overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.magentaLight.withValues(alpha: 0.3), width: 3),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(color: AppColors.magentaLight, strokeWidth: 2),
                          Icon(Icons.science_rounded, color: AppColors.magentaLight.withValues(alpha: 0.5), size: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: AppTheme.glassDecoration(),
                      child: Text(
                        _status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HALAL VERIFICATION IN PROGRESS',
                      style: TextStyle(color: AppColors.magentaLight.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),

          // Result Bottom Sheet
          if (_result != null)
            _ResultSheet(result: _result!, onReset: _reset, blockchainResult: _blockchainResult),

          // Error Notification Banner
          if (_error != null)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C0B0E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final _ScanMode mode;
  final ValueChanged<_ScanMode> onChanged;

  const _ModeSwitcher({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            icon: Icons.document_scanner_rounded,
            label: 'Ingredients',
            selected: mode == _ScanMode.ingredient,
            onTap: () => onChanged(_ScanMode.ingredient),
          ),
          const SizedBox(width: 4),
          _ModeChip(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Barcode',
            selected: mode == _ScanMode.barcode,
            onTap: () => onChanged(_ScanMode.barcode),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.magenta : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: isPrimary
                ? AppTheme.magentaGlow(radius: 26)
                : BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top, left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: AppColors.magentaLight, width: 3.5) : BorderSide.none,
            bottom: !top ? const BorderSide(color: AppColors.magentaLight, width: 3.5) : BorderSide.none,
            left: left ? const BorderSide(color: AppColors.magentaLight, width: 3.5) : BorderSide.none,
            right: !left ? const BorderSide(color: AppColors.magentaLight, width: 3.5) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(12) : Radius.zero,
            topRight: top && !left ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String? tooltip;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: active
            ? BoxDecoration(
                color: AppColors.magenta.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.magentaLight),
              )
            : BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
        child: Icon(icon, color: active ? AppColors.magentaLight : Colors.white, size: 20),
      ),
    );
  }
}

class _ApiItem extends StatelessWidget {
  final String title;
  final String desc;
  final String badge;

  const _ApiItem({required this.title, required this.desc, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.magenta.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: AppColors.magentaLight, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onReset;
  final BlockchainVerificationResult? blockchainResult;

  const _ResultSheet({
    required this.result,
    required this.onReset,
    this.blockchainResult,
  });

  Color get _statusColor {
    switch (result.status) {
      case 'halal':
        return const Color(0xFF34D399);
      case 'haram':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFFFBBF24);
    }
  }

  IconData get _statusIcon {
    switch (result.status) {
      case 'halal':
        return Icons.verified_rounded;
      case 'haram':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  void _copyToClipboard(BuildContext context) {
    final buffer = StringBuffer()
      ..writeln('=== HALAL SCANNER REPORT ===')
      ..writeln('VERDICT: ${result.status.toUpperCase()}')
      ..writeln('REASON: ${result.reason}');
    if (result.productName != null) {
      buffer.writeln('PRODUCT: ${result.productName}');
    }
    if (result.brand != null) {
      buffer.writeln('BRAND: ${result.brand}');
    }
    if (result.isCertifiedHalal) {
      buffer.writeln('CERTIFICATION: Certified Halal');
    }
    buffer.writeln('\nINGREDIENTS:');
    for (final ing in result.ingredients) {
      buffer.writeln('- ${ing.name}: ${ing.status.toUpperCase()}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        backgroundColor: AppColors.magenta,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(28),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Status header
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.status.toUpperCase(),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _statusColor),
                      ),
                      Text(
                        result.reason,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onReset,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Product & Brand Card (if available from Barcode API)
            if (result.productName != null || result.imageUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(radius: 16),
                child: Row(
                  children: [
                    if (result.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          result.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: Colors.white30, size: 40),
                        ),
                      ),
                    if (result.imageUrl != null) const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.brand != null && result.brand!.isNotEmpty)
                            Text(
                              result.brand!.toUpperCase(),
                              style: const TextStyle(color: AppColors.magentaLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          Text(
                            result.productName ?? 'Product',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          if (result.isCertifiedHalal) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'CERTIFIED HALAL ON PACKAGING',
                                  style: TextStyle(color: const Color(0xFF34D399).withValues(alpha: 0.9), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                          if (blockchainResult?.showBadge == true) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.security_rounded, color: Color(0xFF34D399), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'BLOCKCHAIN VERIFIED',
                                  style: TextStyle(color: const Color(0xFF34D399).withValues(alpha: 0.9), fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Purity report
            const Text(
              'DETAILED VERDICT',
              style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(radius: 16),
              child: Text(
                result.purityReport,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // Ingredients
            if (result.ingredients.isNotEmpty) ...[
              Text(
                'INGREDIENT BREAKDOWN (${result.ingredients.length})',
                style: const TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...result.ingredients.map((ing) {
                Color c;
                switch (ing.status) {
                  case 'halal':
                    c = const Color(0xFF34D399);
                    break;
                  case 'haram':
                    c = const Color(0xFFF43F5E);
                    break;
                  default:
                    c = const Color(0xFFFBBF24);
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ing.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ing.status.toUpperCase(),
                          style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Actions row: Copy report + Scan again
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _copyToClipboard(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('Copy Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.magenta,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: onReset,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Scan Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
