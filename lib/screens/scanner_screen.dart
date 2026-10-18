import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/ocr_service.dart';
import '../services/barcode_service.dart';
import '../services/halal_engine.dart';
import '../models/halal_location.dart';
import '../widgets/app_theme.dart';

enum _ScanMode { ingredient, barcode }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isAnalyzing = false;
  bool _isFlashOn = false;
  AnalysisResult? _result;
  String? _error;
  String _status = 'Initializing Scan...';
  _ScanMode _mode = _ScanMode.ingredient;
  final MobileScannerController _barcodeController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _barcodeHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _error = 'Camera permission denied');
      return;
    }
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() => _error = 'No cameras available');
      return;
    }
    // Prefer back camera
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
    await _controller?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
    setState(() => _isFlashOn = false);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    await _controller!.setFlashMode(newMode);
    setState(() => _isFlashOn = !_isFlashOn);
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

      // Pause camera preview while we run on-device OCR.
      await _controller?.pausePreview();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _status = 'Extracting Text (On-Device)...');
      });

      // 1) On-device OCR reads the ingredient label (no cloud API).
      final text = await OcrService.readText(file.path);

      if (mounted) setState(() => _status = 'Checking Halal Rules...');

      // 2) Offline rules engine decides halal status.
      final result = HalalEngine.analyze(text);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
      // Resume camera on error
      await _controller?.resumePreview();
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  /// Handles a detected barcode by looking it up in Open Food Facts and then
  /// running the offline halal rules engine.
  Future<void> _handleBarcode(String barcode) async {
    if (_barcodeHandled) return;
    _barcodeHandled = true;
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _error = null;
      _status = 'Looking up Product...';
    });
    try {
      final result = await BarcodeService.lookupBarcode(barcode);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
      // Allow another scan attempt after a short delay.
      Future.delayed(const Duration(seconds: 2), () => _barcodeHandled = false);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _setMode(_ScanMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _result = null;
      _error = null;
      _barcodeHandled = false;
    });
    if (mode == _ScanMode.barcode) {
      // Release the camera plugin so MobileScanner can use it exclusively.
      _controller?.dispose().then((_) {
        if (mounted) setState(() => _controller = null);
      });
    } else {
      // Returning to ingredient mode: re-acquire the camera.
      if (_controller == null) _startCamera();
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
      _barcodeHandled = false;
    });
    // Resume ingredient camera preview (no-op in barcode mode).
    _controller?.resumePreview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- Mode-specific live view ---
          if (_mode == _ScanMode.ingredient)
            // Ingredient mode: standard camera preview
            if (_controller != null && _controller!.value.isInitialized)
              Positioned.fill(child: CameraPreview(_controller!))
            else
              const Center(child: CircularProgressIndicator(color: AppColors.magenta))
          else
            // Barcode mode: ML Kit barcode scanner
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

          // --- Mode switcher (top center) ---
          if (_result == null && !_isAnalyzing)
            Positioned(top: 55, left: 0, right: 0, child: _ModeSwitcher(
              mode: _mode,
              onChanged: _setMode,
            )),

          // Scanning overlay
          if (!_isAnalyzing && _result == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.magenta, width: 2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Stack(
                      children: [
                        // Corners
                        _Corner(top: true, left: true),
                        _Corner(top: true, left: false),
                        _Corner(top: false, left: true),
                        _Corner(top: false, left: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _mode == _ScanMode.ingredient
                        ? 'Align ingredients within the square'
                        : 'Point camera at a product barcode',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Analyzing overlay with frozen effect
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ANALYZING...',
                      style: TextStyle(color: AppColors.magentaLight.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),

          // Top controls (ingredient mode only)
          if (_mode == _ScanMode.ingredient && _result == null && !_isAnalyzing)
            Positioned(
              top: 60,
              right: 24,
              child: Column(
                children: [
                  _ControlButton(icon: Icons.flip_camera_android_rounded, onTap: _toggleCamera),
                  const SizedBox(height: 12),
                  _ControlButton(
                    icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    onTap: _toggleFlash,
                    active: _isFlashOn,
                  ),

                ],
              ),
            ),

          // Capture button (ingredient mode only)
          if (_mode == _ScanMode.ingredient && _result == null && !_isAnalyzing)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: AppTheme.magentaGlow(radius: 40),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
            ),

          // Result sheet
          if (_result != null)
            _ResultSheet(result: _result!, onReset: _reset),

          // Error
          if (_error != null)
            Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: const Icon(Icons.close_rounded, color: Colors.white54),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeChip(
              icon: Icons.list_alt_rounded,
              label: 'Ingredients',
              selected: mode == _ScanMode.ingredient,
              onTap: () => onChanged(_ScanMode.ingredient),
            ),
            const SizedBox(width: 6),
            _ModeChip(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Barcode',
              selected: mode == _ScanMode.barcode,
              onTap: () => onChanged(_ScanMode.barcode),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.magenta : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: AppColors.magenta, width: 4) : BorderSide.none,
            bottom: !top ? const BorderSide(color: AppColors.magenta, width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: AppColors.magenta, width: 4) : BorderSide.none,
            right: !left ? const BorderSide(color: AppColors.magenta, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(16) : Radius.zero,
            topRight: top && !left ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
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

  const _ControlButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: active
            ? BoxDecoration(
                color: AppColors.magentaLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.magentaLight.withValues(alpha: 0.5)),
              )
            : AppTheme.glassDecoration(radius: 14),
        child: Icon(icon, color: active ? AppColors.magentaLight : Colors.white, size: 22),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onReset;

  const _ResultSheet({required this.result, required this.onReset});

  Color get _statusColor {
    switch (result.status) {
      case 'halal': return const Color(0xFF34D399);
      case 'haram': return const Color(0xFFF43F5E);
      default: return const Color(0xFFFBBF24);
    }
  }

  IconData get _statusIcon {
    switch (result.status) {
      case 'halal': return Icons.check_circle_rounded;
      case 'haram': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
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
            // Handle
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
                Icon(_statusIcon, color: _statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  result.status.toUpperCase(),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _statusColor),
                ),
                const Spacer(),
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

            // Purity report
            const Text('PURITY REPORT',
                style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(radius: 16),
              child: Text('"${result.purityReport}"',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 20),

            // Ingredients
            const Text('INGREDIENT BREAKDOWN',
                style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...result.ingredients.map((ing) {
              Color c;
              switch (ing.status) {
                case 'halal': c = const Color(0xFF34D399); break;
                case 'haram': c = const Color(0xFFF43F5E); break;
                default: c = const Color(0xFFFBBF24);
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
                    Expanded(child: Text(ing.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(ing.status.toUpperCase(),
                          style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Scan again button
            GestureDetector(
              onTap: onReset,
              child: Container(
                height: 56,
                decoration: AppTheme.magentaGlow(radius: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Scan Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
