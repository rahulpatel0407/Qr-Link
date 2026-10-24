import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class FileActionBar extends StatefulWidget {
  final String filePath;
  final String fileName;
  final Uint8List fileBytes;

  const FileActionBar({
    Key? key,
    required this.filePath,
    required this.fileName,
    required this.fileBytes,
  }) : super(key: key);

  @override
  State<FileActionBar> createState() => _FileActionBarState();
}

class _FileActionBarState extends State<FileActionBar> {

  bool get _isTextFile {
    final ext = widget.fileName.split('.').last.toLowerCase();
    return ['txt', 'json', 'csv', 'md', 'html', 'xml'].contains(ext);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: AppColors.white)),
        backgroundColor: AppColors.panel,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cyan),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _saveToDownloads() async {
    try {
      if (kIsWeb) {
        if (widget.fileBytes.isNotEmpty) {
          final xFile = XFile.fromData(widget.fileBytes, name: widget.fileName);
          await Share.shareXFiles([xFile], text: 'Downloaded via QRLink');
          _showSnackbar('File ready / shared: ${widget.fileName}');
        } else {
          _showSnackbar('File downloaded: ${widget.fileName}');
        }
        return;
      }
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDirectory = await getDownloadsDirectory();
      }
      
      if (downloadsDirectory != null) {
        final savePath = '${downloadsDirectory.path}/${widget.fileName}';
        final file = File(savePath);
        await file.writeAsBytes(widget.fileBytes);
        _showSnackbar('Saved to Downloads: ${widget.fileName}');
      } else {
        _showSnackbar('Could not access Downloads directory');
      }
    } catch (e) {
      _showSnackbar('Failed to save file: $e');
    }
  }

  Future<void> _shareFile() async {
    try {
      final xFile = widget.fileBytes.isNotEmpty
          ? XFile.fromData(widget.fileBytes, name: widget.fileName)
          : XFile(widget.filePath);
      await Share.shareXFiles([xFile], text: 'Shared via QRLink');
    } catch (e) {
      _showSnackbar('Failed to share file: $e');
    }
  }

  Future<void> _openFile() async {
    try {
      if (kIsWeb) {
        _showSnackbar('Direct file opening is handled via browser download');
        return;
      }
      final result = await OpenFilex.open(widget.filePath);
      if (result.type != ResultType.done) {
        _showSnackbar('Could not open file: ${result.message}');
      }
    } catch (e) {
      _showSnackbar('Failed to open file: $e');
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      final text = String.fromCharCodes(widget.fileBytes);
      await Clipboard.setData(ClipboardData(text: text));
      _showSnackbar('Copied to clipboard');
    } catch (e) {
      _showSnackbar('Failed to copy to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.download,
          label: 'Save to Downloads',
          onTap: _saveToDownloads,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share via...',
          onTap: _shareFile,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.open_in_new,
          label: 'Open with...',
          onTap: _openFile,
        ),
        if (_isTextFile) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Copy to clipboard',
            onTap: _copyToClipboard,
          ),
        ]
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.slate,
        splashColor: AppColors.cyan.withOpacity(0.2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.slate),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.cyan, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
