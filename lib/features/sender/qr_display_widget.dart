import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class QrDisplayWidget extends StatefulWidget {
  final List<String> frames;
  final int fps;
  final bool isPaused;

  const QrDisplayWidget({
    super.key,
    required this.frames,
    required this.fps,
    this.isPaused = false,
  });

  @override
  State<QrDisplayWidget> createState() => _QrDisplayWidgetState();
}

class _QrDisplayWidgetState extends State<QrDisplayWidget> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startTimer();
  }

  @override
  void didUpdateWidget(QrDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frames != oldWidget.frames) {
      _currentIndex = 0;
    }
    if (widget.fps != oldWidget.fps || widget.isPaused != oldWidget.isPaused) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isPaused || widget.frames.isEmpty) return;

    final duration = Duration(milliseconds: 1000 ~/ widget.fps);
    _timer = Timer.periodic(duration, (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scanAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
    }

    final currentFrame = widget.frames[_currentIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Frame Counter Overlay
        Text(
          'FRAME ${(_currentIndex + 1).toString().padLeft(3, '0')} / ${widget.frames.length.toString().padLeft(3, '0')}',
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 24),

        // QR Code Display with Scanner Effect
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    key: ValueKey<int>(_currentIndex),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: currentFrame,
                      size: 260,
                      version: QrVersions.auto,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Scan Line
                AnimatedBuilder(
                  animation: _scanAnimController,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanAnimController.value * 260,
                      child: Container(
                        width: 260,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.frames.length,
            backgroundColor: AppColors.panel,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
