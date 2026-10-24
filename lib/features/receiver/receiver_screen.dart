import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'camera_viewfinder.dart';
import 'chunk_grid_widget.dart';
import 'receiver_controller.dart';

class ReceiverScreen extends ConsumerStatefulWidget {
  const ReceiverScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends ConsumerState<ReceiverScreen> {
  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final state = ref.read(receiverControllerProvider);
    if (state.isComplete) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        ref.read(receiverControllerProvider.notifier).processScannedData(barcode.rawValue!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiverControllerProvider);
    
    // Listen for complete state to navigate
    ref.listen<ReceiverState>(receiverControllerProvider, (previous, next) {
      if (next.isComplete && previous?.isComplete != true) {
        // Mock navigation to result screen
        Navigator.of(context).pushReplacementNamed('/result');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1525),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE8F4FD)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'RECEIVE FILE',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F5FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: CameraViewfinder(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF111827),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chunks: ${state.receivedChunks.length}/${state.totalChunks == 0 ? '?' : state.totalChunks} received (${(ref.read(receiverControllerProvider.notifier).getProgress() * 100).toStringAsFixed(1)}%)',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE8F4FD),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ref.read(receiverControllerProvider.notifier).getProgress(),
                    backgroundColor: const Color(0xFF4A5568),
                    color: const Color(0xFF7B2FFF),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: _buildSpeedGraph(state.speedHistory),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Session: ${state.sessionId.isEmpty ? 'Waiting...' : state.sessionId}',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF4A5568),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ChunkGridWidget(
                      totalChunks: state.totalChunks,
                      receivedChunks: Set.from(state.receivedChunks.keys),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGraph(List<double> history) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'No speed data',
          style: GoogleFonts.inter(color: const Color(0xFF4A5568)),
        ),
      );
    }
    
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFF6B35),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF6B35).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
