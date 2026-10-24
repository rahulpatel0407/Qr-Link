import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// Dummy model and service for demonstration
class TransferHistoryItem {
  final String id;
  final String fileName;
  final int fileSize;
  final DateTime timestamp;
  final bool isUpload;
  final bool shaVerified;
  
  TransferHistoryItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.timestamp,
    required this.isUpload,
    required this.shaVerified,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  List<TransferHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    // Simulate SQLite load
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _history = [
        TransferHistoryItem(
          id: 'SESS-8F92A',
          fileName: 'project_backup.zip',
          fileSize: 4500000,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isUpload: true,
          shaVerified: true,
        ),
        TransferHistoryItem(
          id: 'SESS-2C44B',
          fileName: 'config.json',
          fileSize: 12000,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isUpload: false,
          shaVerified: true,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('Delete Transfer?', style: GoogleFonts.orbitron(color: AppColors.white)),
        content: Text('Are you sure you want to delete this from history?', style: GoogleFonts.inter(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.amber)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _history.removeWhere((item) => item.id == id);
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.slate,
        title: Text(
          'TRANSFER HISTORY',
          style: GoogleFonts.orbitron(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.cyan),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
        : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: AppColors.muted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No transfers yet',
                    style: GoogleFonts.inter(color: AppColors.muted, fontSize: 18),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.cyan,
              backgroundColor: AppColors.panel,
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Card(
                    color: AppColors.panel,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.slate),
                    ),
                    child: InkWell(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.panel,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.share, color: AppColors.cyan),
                                title: Text('Re-share', style: GoogleFonts.inter(color: AppColors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  // Re-share logic
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: AppColors.amber),
                                title: Text('Delete', style: GoogleFonts.inter(color: AppColors.amber)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _deleteItem(item.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (item.isUpload ? AppColors.violet : AppColors.cyan).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.isUpload ? Icons.arrow_upward : Icons.arrow_downward,
                                color: item.isUpload ? AppColors.violet : AppColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.fileName,
                                    style: GoogleFonts.inter(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        _formatBytes(item.fileSize),
                                        style: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '•',
                                        style: TextStyle(color: AppColors.muted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _relativeTime(item.timestamp),
                                        style: GoogleFonts.inter(color: AppColors.muted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${item.id}',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              item.shaVerified ? Icons.verified : Icons.warning,
                              color: item.shaVerified ? AppColors.cyan : AppColors.amber,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                },
              ),
            ),
    );
  }
}
