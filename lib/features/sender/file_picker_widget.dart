import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import '../../theme/app_colors.dart';

class FilePickerWidget extends StatefulWidget {
  final Function(String path, int size, String type) onFileSelected;
  final VoidCallback onStartTransfer;
  final bool isFileSelected;
  final String fileName;
  final int fileSize;
  final String fileType;
  final bool isCompressing;

  const FilePickerWidget({
    super.key,
    required this.onFileSelected,
    required this.onStartTransfer,
    this.isFileSelected = false,
    this.fileName = '',
    this.fileSize = 0,
    this.fileType = '',
    this.isCompressing = false,
  });

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  String _compressionMode = 'Auto';
  bool _encryptionEnabled = false;
  final TextEditingController _passphraseController = TextEditingController();

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true, // Required for web — loads bytes directly
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = file.extension ?? '';
        // Use file.name on web (path is unavailable), path on mobile
        final identifier = file.name;
        widget.onFileSelected(identifier, file.size, ext);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drop Zone
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.slate.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isFileSelected ? AppColors.cyan : AppColors.muted,
                  width: 2,
                  style: BorderStyle.solid, // Should ideally be dashed
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isFileSelected ? Icons.file_present_rounded : Icons.cloud_upload_rounded,
                    size: 64,
                    color: widget.isFileSelected ? AppColors.cyan : AppColors.muted,
                  ),
                  const SizedBox(height: 16),
                  if (widget.isFileSelected) ...[
                    Text(
                      widget.fileName,
                      style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.fileSize / 1024).toStringAsFixed(1)} KB • ${widget.fileType.toUpperCase()}',
                      style: GoogleFonts.jetBrainsMono(color: AppColors.muted, fontSize: 12),
                    ),
                  ] else ...[
                    Text(
                      'Tap to select a file',
                      style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Any file up to 50MB',
                      style: GoogleFonts.inter(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          if (widget.isFileSelected) ...[
            // Compression Options
            Text('Compression', style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _OptionCard(
                    title: 'Auto',
                    isSelected: _compressionMode == 'Auto',
                    onTap: () => setState(() => _compressionMode = 'Auto'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OptionCard(
                    title: 'GZip',
                    isSelected: _compressionMode == 'GZip',
                    onTap: () => setState(() => _compressionMode = 'GZip'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Encryption Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Encryption', style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14)),
                Switch(
                  value: _encryptionEnabled,
                  onChanged: (val) => setState(() => _encryptionEnabled = val),
                  activeColor: AppColors.cyan,
                  inactiveTrackColor: AppColors.slate,
                ),
              ],
            ),
            
            if (_encryptionEnabled) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passphraseController,
                obscureText: true,
                style: GoogleFonts.jetBrainsMono(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Passphrase',
                  hintStyle: GoogleFonts.inter(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.slate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.muted),
                ),
              ),
            ],

            const Spacer(),

            // Start Button
            ElevatedButton(
              onPressed: widget.isCompressing ? null : widget.onStartTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: widget.isCompressing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 3),
                  )
                : Text(
                    'Start Transfer',
                    style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
            ),
          ]
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan.withOpacity(0.1) : AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.slate,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? AppColors.cyan : AppColors.muted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
