import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/txqr_service.dart';
import '../widgets/qr_scanner_overlay.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TxqrService _txqr = TxqrService();
  late final MobileScannerController _cameraController;

  int _progress = 0;
  String _speed = '';
  String _statusText = 'Point camera at animated QR code';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      detectionTimeoutMs: 50,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      _processing = true;
      try {
        final error = await _txqr.decode(raw);
        if (error != null && error.isNotEmpty) {
          // Not a TXQR frame – ignore silently
          _processing = false;
          continue;
        }

        final completed = await _txqr.isCompleted();
        final progress = await _txqr.getProgress();
        final speed = await _txqr.getSpeed();

        if (!mounted) return;
        setState(() {
          _progress = progress;
          _speed = speed;
          _statusText = 'Receiving… $progress%';
        });

        if (completed) {
          final data = await _txqr.getData();
          final totalTime = await _txqr.getTotalTime();

          if (!mounted) return;
          final nav = Navigator.of(context);
          await _cameraController.stop();
          await nav.push(
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                data: data,
                totalTime: totalTime,
                speed: speed,
              ),
            ),
          );
          // Returned from result screen – reset for next scan
          await _txqr.reset();
          setState(() {
            _progress = 0;
            _speed = '';
            _statusText = 'Point camera at animated QR code';
          });
          await _cameraController.start();
        }
      } catch (e) {
        debugPrint('TXQR decode error: $e');
      } finally {
        _processing = false;
      }
    }
  }

  Future<void> _onReset() async {
    await _txqr.reset();
    setState(() {
      _progress = 0;
      _speed = '';
      _statusText = 'Point camera at animated QR code';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // Overlay with scan window & progress arc
          QrScannerOverlay(progress: _progress / 100),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInfoPanel(),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'TXQR Scanner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Reset',
                      onPressed: _onReset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
            ),
          ),
          const SizedBox(height: 12),
          // Status row
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              if (_speed.isNotEmpty)
                Text(
                  _speed,
                  style: const TextStyle(
                    color: Colors.indigoAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
