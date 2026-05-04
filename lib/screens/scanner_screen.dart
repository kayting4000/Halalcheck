import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_service.dart';
import '../models/halal_location.dart';
import '../widgets/app_theme.dart';

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
      _status = 'Capturing Ingredients...';
    });

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Pause camera preview
      await _controller?.pausePreview();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _status = 'Isolating Molecules...');
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _status = 'Checking Halal DB...');
      });

      final result = await GeminiService.analyzeIngredients(bytes);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
      // Resume camera on error
      await _controller?.resumePreview();
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
    });
    // Resume camera preview
    _controller?.resumePreview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: AppColors.magenta)),

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
                  const Text(
                    'Align ingredients within the square',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
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

          // Top controls
          if (_result == null && !_isAnalyzing)
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

          // Capture button
          if (_result == null && !_isAnalyzing)
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
