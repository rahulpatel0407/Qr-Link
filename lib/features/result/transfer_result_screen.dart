import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'file_action_bar.dart';

// Assuming a TransferResult model exists in the app:
class TransferResult {
  final bool success;
  final String fileName;
  final int originalSize;
  final int compressedSize;
  final double transferTime;
  final double throughput;
  final bool shaVerified;
  final String sha256;
  final String filePath;
  final Uint8List fileBytes;

  TransferResult({
    required this.success,
    required this.fileName,
    required this.originalSize,
    required this.compressedSize,
    required this.transferTime,
    required this.throughput,
    required this.shaVerified,
    required this.sha256,
    required this.filePath,
    required this.fileBytes,
  });
}

class TransferResultScreen extends StatelessWidget {
  const TransferResultScreen({Key? key}) : super(key: key);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final result = ModalRoute.of(context)!.settings.arguments as TransferResult;
    
    final ratio = result.originalSize > 0 
        ? ((1 - (result.compressedSize / result.originalSize)) * 100).toStringAsFixed(0) 
        : '0';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.slate,
        title: Text(
          'TRANSFER RESULT',
          style: GoogleFonts.orbitron(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.cyan),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: result.success && result.shaVerified ? AppColors.cyan.withOpacity(0.1) : AppColors.amber.withOpacity(0.1),
                ),
                child: Icon(
                  result.success && result.shaVerified ? Icons.check_circle_outline : Icons.error_outline,
                  size: 80,
                  color: result.success && result.shaVerified ? AppColors.cyan : AppColors.amber,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 24),
            
            // File Name
            Text(
              result.fileName,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 32),

            // Stats Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate),
              ),
              child: Column(
                children: [
                  _buildStatRow('Original Size', _formatBytes(result.originalSize)),
                  const Divider(color: AppColors.slate, height: 24),
                  _buildStatRow('Compressed Size', _formatBytes(result.compressedSize)),
                  const Divider(color: AppColors.slate, height: 24),
                  _buildStatRow('Compression', '$ratio% ↓', valueColor: AppColors.cyan),
                  const Divider(color: AppColors.slate, height: 24),
                  _buildStatRow('Transfer Time', '${result.transferTime.toStringAsFixed(1)} seconds'),
                  const Divider(color: AppColors.slate, height: 24),
                  _buildStatRow('Throughput', '${result.throughput.toStringAsFixed(1)} KB/s'),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),

            // SHA-256 Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.shaVerified ? AppColors.panel : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: result.shaVerified ? AppColors.slate : Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        result.shaVerified ? Icons.verified : Icons.warning,
                        color: result.shaVerified ? AppColors.cyan : AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.shaVerified ? 'SHA-256 verified ✓' : 'Integrity Check Failed',
                        style: GoogleFonts.inter(
                          color: result.shaVerified ? AppColors.cyan : AppColors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.sha256.length > 16 
                      ? '${result.sha256.substring(0, 16)}...${result.sha256.substring(result.sha256.length - 16)}'
                      : result.sha256,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),

            if (result.success && result.shaVerified)
              FileActionBar(
                filePath: result.filePath,
                fileName: result.fileName,
                fileBytes: result.fileBytes,
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cyan),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'New Transfer',
                      style: GoogleFonts.inter(color: AppColors.cyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: valueColor ?? AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
