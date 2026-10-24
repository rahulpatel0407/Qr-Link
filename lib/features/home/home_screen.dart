import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.slate.withOpacity(0.5),
                      AppColors.black,
                    ],
                    center: Alignment(
                      0.5 * _bgAnimController.value,
                      0.5 * (1 - _bgAnimController.value),
                    ),
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QRLink',
                        style: GoogleFonts.orbitron(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ).animate().fade().slideY(begin: -0.2),
                      IconButton(
                        icon: const Icon(Icons.settings, color: AppColors.muted),
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                      ).animate().fade().scale(),
                    ],
                  ),
                ),

                const Spacer(),

                // Mode Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _ModeCard(
                        title: 'SEND',
                        subtitle: 'Transfer a file from this device',
                        icon: Icons.upload_rounded,
                        accentColor: AppColors.cyan,
                        onTap: () => Navigator.pushNamed(context, '/send'),
                      ).animate().fade(delay: 200.ms).slideX(begin: -0.2),
                      
                      const SizedBox(height: 24),
                      
                      _ModeCard(
                        title: 'RECEIVE',
                        subtitle: 'Scan a QR stream to receive a file',
                        icon: Icons.download_rounded,
                        accentColor: AppColors.violet,
                        onTap: () => Navigator.pushNamed(context, '/receive'),
                      ).animate().fade(delay: 400.ms).slideX(begin: 0.2),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/history'),
                        icon: const Icon(Icons.history, color: AppColors.muted, size: 20),
                        label: Text(
                          'History',
                          style: GoogleFonts.inter(color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'v1.0.0',
                        style: GoogleFonts.jetBrainsMono(color: AppColors.muted.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ).animate().fade(delay: 600.ms),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
),
        ],
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) {
          setState(() => _isHovered = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? widget.accentColor.withOpacity(0.5) : AppColors.slate,
              width: 2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.orbitron(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
