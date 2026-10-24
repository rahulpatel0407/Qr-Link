import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import 'file_picker_widget.dart';
import 'qr_display_widget.dart';
import 'sender_controller.dart';

class SenderScreen extends ConsumerStatefulWidget {
  const SenderScreen({super.key});

  @override
  ConsumerState<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends ConsumerState<SenderScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(senderControllerProvider);
    final controller = ref.read(senderControllerProvider.notifier);
    final isStreaming = state.qrFrames.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () {
            if (isStreaming) {
              controller.reset();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          isStreaming ? 'STREAMING QR' : 'SEND FILE',
          style: GoogleFonts.orbitron(
            color: AppColors.cyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          if (isStreaming)
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
          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.amber.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: GoogleFonts.inter(color: AppColors.amber, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !isStreaming
                  ? FilePickerWidget(
                      key: const ValueKey(0),
                      isFileSelected: state.fileBytes != null && state.fileBytes!.isNotEmpty,
                      fileName: state.fileName ?? '',
                      fileSize: state.fileSize,
                      fileType: (state.fileName ?? '').split('.').last,
                      isCompressing: state.status == SenderStatus.compressing ||
                          state.status == SenderStatus.chunking ||
                          state.status == SenderStatus.generating,
                      onFileSelected: (name, size, type, bytes) {
                        controller.setFileBytes(name: name, size: size, bytes: bytes);
                      },
                      onStartTransfer: (encrypt, passphrase, compression) {
                        controller.startTransfer(
                          encrypt: encrypt,
                          passphrase: passphrase,
                          compression: compression,
                        );
                      },
                    )
                  : QrDisplayWidget(
                      key: const ValueKey(1),
                      frames: state.qrFrames,
                      fps: state.fps,
                      isPaused: state.isPaused,
                    ),
            ),
          ),
          
          if (isStreaming) ...[
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
                        style: GoogleFonts.jetBrainsMono(color: AppColors.cyan, fontWeight: FontWeight.bold),
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
                              color: state.isLooping ? AppColors.cyan : AppColors.muted,
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
                          state.fileName ?? 'Transferring File',
                          style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${state.chunks.length} chunks',
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
