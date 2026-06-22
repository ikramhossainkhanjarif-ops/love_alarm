import 'package:equatable/equatable.dart';

/// A single selectable alarm tone: a friendly display name paired with its
/// bundled asset path. Used by the sound picker in the alarm editor.
class SoundOption extends Equatable {
  final String name;
  final String assetPath;

  const SoundOption({required this.name, required this.assetPath});

  @override
  List<Object?> get props => [name, assetPath];
}

/// All built-in alarm tones bundled with the app. Add more here any time —
/// just drop the .mp3 into assets/sounds/ and list it below; no other code
/// changes needed.
class SoundCatalog {
  SoundCatalog._();

  static const List<SoundOption> options = [
    SoundOption(
      name: 'Sweet Chime',
      assetPath: 'assets/sounds/sweet_chime.mp3',
    ),
    SoundOption(
      name: 'Gentle Bells',
      assetPath: 'assets/sounds/gentle_bells.mp3',
    ),
    SoundOption(
      name: 'Morning Sparkle',
      assetPath: 'assets/sounds/morning_sparkle.mp3',
    ),
    SoundOption(
      name: 'Soft Piano',
      assetPath: 'assets/sounds/soft_piano.mp3',
    ),
    SoundOption(
      name: 'Heartbeat Chime',
      assetPath: 'assets/sounds/heartbeat_chime.mp3',
    ),
  ];

  static const SoundOption defaultOption = options[0];

  /// Looks up the display option matching a stored asset path, falling
  /// back to the default if the path is unrecognized (e.g. an alarm saved
  /// before a sound was removed from the catalog).
  static SoundOption fromAssetPath(String assetPath) {
    return options.firstWhere(
      (o) => o.assetPath == assetPath,
      orElse: () => defaultOption,
    );
  }
}
