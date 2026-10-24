import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChunkGridWidget extends StatelessWidget {
  final int totalChunks;
  final Set<int> receivedChunks;

  const ChunkGridWidget({
    Key? key,
    required this.totalChunks,
    required this.receivedChunks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool compressed = totalChunks > 200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chunk Map',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F5FF),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${receivedChunks.length} / $totalChunks Received',
          style: GoogleFonts.inter(
            color: const Color(0xFFE8F4FD),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: compressed ? _buildCompressedView() : _buildGridView(),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(totalChunks, (index) {
        bool received = receivedChunks.contains(index);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: received ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF0D1525)),
          ),
        );
      }),
    );
  }

  Widget _buildCompressedView() {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: List.generate(totalChunks, (index) {
        bool received = receivedChunks.contains(index);
        return Container(
          width: 4,
          height: 12,
          color: received ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        );
      }),
    );
  }
}
