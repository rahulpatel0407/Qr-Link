import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

// Settings state provider
final settingsProvider = ChangeNotifierProvider((ref) => SettingsNotifier());

class SettingsNotifier extends ChangeNotifier {
  double chunkSize = 1000;
  int fps = 15;
  String compression = 'Auto';
  String errorCorrection = 'M';
  
  bool blurDetection = true;
  bool adaptiveDensity = true;
  bool lowLightEnhancement = false;
  
  double retransmitTimeout = 3.0;
  bool screenBrightnessLock = true;
  
  String historyRetention = '30 days';

  void updateChunkSize(double value) { chunkSize = value; notifyListeners(); }
  void updateFps(int value) { fps = value; notifyListeners(); }
  void updateCompression(String value) { compression = value; notifyListeners(); }
  void updateErrorCorrection(String value) { errorCorrection = value; notifyListeners(); }
  void toggleBlurDetection(bool value) { blurDetection = value; notifyListeners(); }
  void toggleAdaptiveDensity(bool value) { adaptiveDensity = value; notifyListeners(); }
  void toggleLowLight(bool value) { lowLightEnhancement = value; notifyListeners(); }
  void updateRetransmit(double value) { retransmitTimeout = value; notifyListeners(); }
  void toggleBrightness(bool value) { screenBrightnessLock = value; notifyListeners(); }
  void updateRetention(String value) { historyRetention = value; notifyListeners(); }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.slate,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.cyan),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Transfer Settings'),
          _buildCard([
            _buildSliderSetting(
              label: 'Chunk Size: ${settings.chunkSize.toInt()} bytes',
              value: settings.chunkSize,
              min: 200,
              max: 2000,
              onChanged: ref.read(settingsProvider.notifier).updateChunkSize,
            ),
            const Divider(color: AppColors.slate, height: 1),
            _buildSegmentedSetting<int>(
              label: 'FPS (Frames per second)',
              value: settings.fps,
              options: const [5, 10, 15, 20, 30],
              onChanged: ref.read(settingsProvider.notifier).updateFps,
            ),
            const Divider(color: AppColors.slate, height: 1),
            _buildDropdownSetting(
              label: 'Compression',
              value: settings.compression,
              options: const ['Auto', 'GZip', 'None'],
              onChanged: (v) => ref.read(settingsProvider.notifier).updateCompression(v!),
            ),
            const Divider(color: AppColors.slate, height: 1),
            _buildSegmentedSetting<String>(
              label: 'Error Correction Level',
              value: settings.errorCorrection,
              options: const ['L', 'M', 'Q', 'H'],
              onChanged: ref.read(settingsProvider.notifier).updateErrorCorrection,
            ),
          ]),

          _buildSectionHeader('AI Optimization'),
          _buildCard([
            _buildSwitchSetting(
              label: 'Blur Detection',
              value: settings.blurDetection,
              onChanged: ref.read(settingsProvider.notifier).toggleBlurDetection,
            ),
            const Divider(color: AppColors.slate, height: 1),
            _buildSwitchSetting(
              label: 'Adaptive QR Density',
              value: settings.adaptiveDensity,
              onChanged: ref.read(settingsProvider.notifier).toggleAdaptiveDensity,
            ),
            const Divider(color: AppColors.slate, height: 1),
            _buildSwitchSetting(
              label: 'Low-light Enhancement',
              value: settings.lowLightEnhancement,
              onChanged: ref.read(settingsProvider.notifier).toggleLowLight,
            ),
          ]),

          _buildSectionHeader('Transfer Behavior'),
          _buildCard([
            _buildSliderSetting(
              label: 'Retransmit Timeout: ${settings.retransmitTimeout.toInt()}s',
              value: settings.retransmitTimeout,
              min: 1,
              max: 10,
              onChanged: ref.read(settingsProvider.notifier).updateRetransmit,
            ),
            const Divider(color: AppColors.slate, height: 1),
            _buildSwitchSetting(
              label: 'Screen Brightness Lock',
              value: settings.screenBrightnessLock,
              onChanged: ref.read(settingsProvider.notifier).toggleBrightness,
            ),
          ]),

          _buildSectionHeader('Data & Privacy'),
          _buildCard([
            _buildDropdownSetting(
              label: 'History Retention',
              value: settings.historyRetention,
              options: const ['7 days', '30 days', 'Forever'],
              onChanged: (v) => ref.read(settingsProvider.notifier).updateRetention(v!),
            ),
            const Divider(color: AppColors.slate, height: 1),
            ListTile(
              title: Text('Clear All History', style: GoogleFonts.inter(color: AppColors.amber, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.delete_forever, color: AppColors.amber),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.panel,
                    title: Text('Clear History', style: GoogleFonts.orbitron(color: AppColors.white)),
                    content: Text('Are you sure you want to clear all transfer history?', style: GoogleFonts.inter(color: AppColors.muted)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.muted))),
                      TextButton(
                        onPressed: () {
                          // Clear history logic
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('History cleared'), backgroundColor: AppColors.panel)
                          );
                        },
                        child: Text('Clear', style: GoogleFonts.inter(color: AppColors.amber)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.orbitron(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchSetting({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(label, style: GoogleFonts.inter(color: AppColors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.cyan,
      activeTrackColor: AppColors.cyan.withOpacity(0.3),
      inactiveThumbColor: AppColors.muted,
      inactiveTrackColor: AppColors.slate,
    );
  }

  Widget _buildSliderSetting({required String label, required double value, required double min, required double max, required ValueChanged<double> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.white)),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.cyan,
            inactiveColor: AppColors.slate,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({required String label, required String value, required List<String> options, required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.white)),
          DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.slate,
            style: GoogleFonts.inter(color: AppColors.cyan),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.cyan),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSetting<T>({required String label, required T value, required List<T> options, required ValueChanged<T> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: options.map((option) {
              final isSelected = value == option;
              return ChoiceChip(
                label: Text(option.toString(), style: GoogleFonts.jetBrainsMono(color: isSelected ? AppColors.black : AppColors.cyan)),
                selected: isSelected,
                selectedColor: AppColors.cyan,
                backgroundColor: AppColors.slate,
                onSelected: (selected) {
                  if (selected) onChanged(option);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
