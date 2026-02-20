import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/txqr_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TxqrService _txqr = TxqrService();

  // File state
  String? _fileName;
  int _fileSize = 0;

  // Encoding state
  bool _isEncoding = false;
  bool _isReady = false;
  int _chunkCount = 0;
  int _currentChunk = 0;
  String _currentQrData = '';

  // Animation
  Timer? _animationTimer;
  int _fps = 8;
  int _loopCount = 0;

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _isEncoding = true;
      _isReady = false;
      _fileName = file.name;
      _fileSize = file.size;
    });

    try {
      // Read file bytes
      final bytes = await File(file.path!).readAsBytes();

      // Create payload: filename + newline + base64 content
      final base64Content = base64Encode(bytes);
      final payload = '${file.name}\n$base64Content';

      // Encode via Go
      await _txqr.encode(payload);
      final count = await _txqr.chunkCount();

      if (count == 0) {
        throw Exception('Encoding produced no chunks');
      }

      // Get the first chunk
      final firstChunk = await _txqr.getChunk(0);

      setState(() {
        _chunkCount = count;
        _currentChunk = 0;
        _currentQrData = firstChunk;
        _isEncoding = false;
        _isReady = true;
        _loopCount = 0;
      });

      _startAnimation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEncoding = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error encoding file: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      Duration(milliseconds: (1000 / _fps).round()),
      (_) => _nextChunk(),
    );
  }

  Future<void> _nextChunk() async {
    final nextIndex = (_currentChunk + 1) % _chunkCount;
    if (nextIndex == 0) {
      _loopCount++;
    }
    final chunk = await _txqr.getChunk(nextIndex);
    if (!mounted) return;
    setState(() {
      _currentChunk = nextIndex;
      _currentQrData = chunk;
    });
  }

  void _setFps(int fps) {
    setState(() {
      _fps = fps;
    });
    if (_isReady) {
      _startAnimation();
    }
  }

  void _reset() {
    _animationTimer?.cancel();
    setState(() {
      _fileName = null;
      _fileSize = 0;
      _isReady = false;
      _chunkCount = 0;
      _currentChunk = 0;
      _currentQrData = '';
      _loopCount = 0;
    });
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send File'),
        centerTitle: true,
        actions: [
          if (_isReady)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Choose another file',
              onPressed: _reset,
            ),
        ],
      ),
      body: _isReady
          ? _buildQrDisplay(theme)
          : _buildFilePicker(theme),
    );
  }

  Widget _buildFilePicker(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(32),
              ),
              child: _isEncoding
                  ? const Center(child: CircularProgressIndicator())
                  : Icon(
                      Icons.folder_open_rounded,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              _isEncoding ? 'Encoding...' : 'Select a file to send',
              style: theme.textTheme.titleLarge,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 8),
              Text(
                '$_fileName (${_humanSize(_fileSize)})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (!_isEncoding)
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Choose File'),
              ),
            const SizedBox(height: 48),
            Text(
              'The file will be encoded into\nanimated QR codes for transfer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrDisplay(ThemeData theme) {
    return Column(
      children: [
        // File info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'Unknown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _humanSize(_fileSize),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Loop $_loopCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // QR code display
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: _currentQrData,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
              ),
            ),
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frame ${_currentChunk + 1} of $_chunkCount',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${((_currentChunk + 1) / _chunkCount * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentChunk + 1) / _chunkCount,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),

        // FPS control
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Animation Speed',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final fps in [4, 6, 8, 10, 12])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$fps'),
                        selected: _fps == fps,
                        onSelected: (_) => _setFps(fps),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Point the receiver\'s camera at this screen',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
