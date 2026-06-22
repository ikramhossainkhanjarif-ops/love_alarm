import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_hearts_background.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/datasources/native_alarm_scheduler.dart';
import '../../domain/usecases/get_todays_message_usecase.dart';

/// The full-screen experience shown when an alarm fires. Launched either:
///  - directly by the native full-screen intent (cold start), or
///  - by the Dart-side native-event listener while the app is alive.
class RingingScreen extends StatefulWidget {
  final String alarmId;
  final GetTodaysMessageUseCase getTodaysMessageUseCase;
  final int snoozeMinutes;

  const RingingScreen({
    super.key,
    required this.alarmId,
    required this.getTodaysMessageUseCase,
    required this.snoozeMinutes,
  });

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen>
    with SingleTickerProviderStateMixin {
  String _message = '';
  bool _loadingMessage = true;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _loadMessage();
  }

  Future<void> _loadMessage() async {
    try {
      final msg = await widget.getTodaysMessageUseCase();
      if (mounted) {
        setState(() {
          _message = msg.text;
          _loadingMessage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'You are loved more than words can say. ❤️';
          _loadingMessage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _dismiss() async {
    await NativeAlarmScheduler.stopRinging();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    await NativeAlarmScheduler.snooze(widget.alarmId, widget.snoozeMinutes);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back-button dismissal; must use buttons.
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Romantic background image with a soft gradient overlay so
            // text always stays readable regardless of the photo used.
            Image.asset(
              AppConstants.backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.ringingGradient,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            const Positioned.fill(
              child: AnimatedHeartsBackground(
                heartCount: 22,
                maxSize: 38,
                minSize: 14,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    const Spacer(),
                    Text(
                      TimeFormatter.formatClock(_now),
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      TimeFormatter.formatAmPm(_now).toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TimeFormatter.formatFullDate(_now),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 36),
                    ScaleTransition(
                      scale: Tween(begin: 0.96, end: 1.04).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: _loadingMessage
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.4,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: _RingingButton(
                            label: 'Snooze',
                            icon: Icons.snooze_rounded,
                            background: Colors.white.withOpacity(0.25),
                            foreground: Colors.white,
                            onTap: _snooze,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RingingButton(
                            label: 'Dismiss',
                            icon: Icons.favorite,
                            background: AppColors.primaryPink,
                            foreground: Colors.white,
                            onTap: _dismiss,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _RingingButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
