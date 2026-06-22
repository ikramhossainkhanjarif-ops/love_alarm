import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../core/constants/sound_catalog.dart';
import '../../core/theme/app_colors.dart';

/// Shows a bottom sheet letting the user pick one of the bundled alarm
/// tones, with a tap-to-preview play/stop button on each row. Returns the
/// chosen [SoundOption.assetPath], or null if the user dismissed without
/// changing anything.
Future<String?> showSoundPickerSheet({
  required BuildContext context,
  required String currentAssetPath,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _SoundPickerSheet(currentAssetPath: currentAssetPath),
  );
}

class _SoundPickerSheet extends StatefulWidget {
  final String currentAssetPath;
  const _SoundPickerSheet({required this.currentAssetPath});

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  late String _selected;
  final _player = AudioPlayer();
  String? _previewingAssetPath;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAssetPath;
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _previewingAssetPath = null);
    });
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(SoundOption option) async {
    if (_previewingAssetPath == option.assetPath) {
      await _player.stop();
      setState(() => _previewingAssetPath = null);
      return;
    }
    await _player.stop();
    // AssetSource paths are relative to the `assets/` root automatically
    // stripped of the leading "assets/" by audioplayers' convention.
    final source = option.assetPath.replaceFirst('assets/', '');
    await _player.play(AssetSource(source));
    setState(() => _previewingAssetPath = option.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.softPink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: AppColors.primaryPink),
                    const SizedBox(width: 8),
                    Text(
                      'Alarm Sound',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: SoundCatalog.options.length,
                  itemBuilder: (context, index) {
                    final option = SoundCatalog.options[index];
                    final isSelected = option.assetPath == _selected;
                    final isPreviewing =
                        option.assetPath == _previewingAssetPath;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.softPink.withOpacity(0.45)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPink
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selected = option.assetPath),
                        leading: GestureDetector(
                          onTap: () => _togglePreview(option),
                          child: CircleAvatar(
                            backgroundColor: AppColors.primaryPink,
                            child: Icon(
                              isPreviewing
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          option.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primaryPink)
                            : const Icon(Icons.circle_outlined,
                                color: AppColors.textMuted),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _player.stop();
                      Navigator.of(context).pop(_selected);
                    },
                    child: const Text('Use this sound'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
