import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import 'file_picker_widget.dart';
import 'qr_display_widget.dart';

// Sender State Model
class SenderState {
  final int step; // 0: File Picker, 1: QR Display
  final String filePath;
  final int fileSize;
  final String fileName;
  final String fileType;
  final bool isCompressing;
  final List<String> qrFrames;
  final int fps;
  final bool isPaused;
  final bool loopFrames;
  final String sessionId;

  SenderState({
    this.step = 0,
    this.filePath = '',
    this.fileSize = 0,
    this.fileName = '',
    this.fileType = '',
    this.isCompressing = false,
    this.qrFrames = const [],
    this.fps = 10,
    this.isPaused = false,
    this.loopFrames = true,
    this.sessionId = '',
  });

  SenderState copyWith({
    int? step,
    String? filePath,
    int? fileSize,
    String? fileName,
    String? fileType,
    bool? isCompressing,
    List<String>? qrFrames,
    int? fps,
    bool? isPaused,
    bool? loopFrames,
    String? sessionId,
  }) {
    return SenderState(
      step: step ?? this.step,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      isCompressing: isCompressing ?? this.isCompressing,
      qrFrames: qrFrames ?? this.qrFrames,
      fps: fps ?? this.fps,
      isPaused: isPaused ?? this.isPaused,
      loopFrames: loopFrames ?? this.loopFrames,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

// Sender Controller
class SenderController extends StateNotifier<SenderState> {
  SenderController() : super(SenderState(sessionId: _generateSessionId()));

  static String _generateSessionId() {
    return (1000 + Random().nextInt(9000)).toString(); // Simple 4-digit ID
  }

  void fileSelected(String path, int size, String type) {
    state = state.copyWith(
      filePath: path,
      fileSize: size,
      fileName: path.split('/').last,
      fileType: type,
    );
  }

  Future<void> startTransfer() async {
    state = state.copyWith(isCompressing: true);
    
    // Simulate File Processing (Read -> Compress -> Encrypt -> Chunk)
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate dummy QR frames
    List<String> mockFrames = List.generate(
      50, 
      (index) => base64UrlEncode(utf8.encode('QRLink_Frame_${index}_${state.sessionId}'))
    );

    state = state.copyWith(
      isCompressing: false,
      step: 1, // Move to QR Display
      qrFrames: mockFrames,
    );
    
    // NOTE: Wakelock and screen brightness should be handled here via plugins
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void setFps(int fps) {
    state = state.copyWith(fps: fps);
  }

  void toggleLoop() {
    state = state.copyWith(loopFrames: !state.loopFrames);
  }

  void reset() {
    state = SenderState(sessionId: _generateSessionId());
  }
}

final senderProvider = StateNotifierProvider<SenderController, SenderState>((ref) {
  return SenderController();
});

// Sender Screen
class SenderScreen extends ConsumerStatefulWidget {
  const SenderScreen({super.key});

  @override
  ConsumerState<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends ConsumerState<SenderScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(senderProvider);
    final controller = ref.read(senderProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () {
            if (state.step == 1) {
              controller.reset();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'SEND FILE',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          if (state.step == 1)
            IconButton(
              icon: Icon(
                state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: AppColors.white,
              ),
              onPressed: controller.togglePause,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.step == 0
                  ? FilePickerWidget(
                      key: const ValueKey(0),
                      isFileSelected: state.filePath.isNotEmpty,
                      fileName: state.fileName,
                      fileSize: state.fileSize,
                      fileType: state.fileType,
                      isCompressing: state.isCompressing,
                      onFileSelected: controller.fileSelected,
                      onStartTransfer: controller.startTransfer,
                    )
                  : QrDisplayWidget(
                      key: const ValueKey(1),
                      frames: state.qrFrames,
                      fps: state.fps,
                      isPaused: state.isPaused,
                    ),
            ),
          ),
          
          if (state.step == 1) ...[
            // Bottom Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Session: #${state.sessionId}',
                        style: GoogleFonts.jetBrainsMono(color: AppColors.cyan),
                      ),
                      Row(
                        children: [
                          Text('FPS: ', style: GoogleFonts.inter(color: AppColors.muted)),
                          DropdownButton<int>(
                            value: state.fps,
                            dropdownColor: AppColors.slate,
                            underline: const SizedBox(),
                            style: GoogleFonts.jetBrainsMono(color: AppColors.white),
                            items: [5, 10, 15, 20, 30].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) controller.setFps(val);
                            },
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: controller.toggleLoop,
                            child: Icon(
                              Icons.loop_rounded,
                              color: state.loopFrames ? AppColors.cyan : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          state.fileName,
                          style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Est. Time: ~2m',
                        style: GoogleFonts.inter(color: AppColors.amber),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
