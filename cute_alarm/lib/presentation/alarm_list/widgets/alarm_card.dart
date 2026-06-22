import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../domain/entities/alarm_entity.dart';

class AlarmCard extends StatelessWidget {
  final AlarmEntity alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = alarm.isEnabled;
    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.heartRed,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? AppColors.cardGradient
                  : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink
                    .withOpacity(enabled ? 0.18 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          TimeFormatter.formatHourMinute(
                              alarm.hour, alarm.minute),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: enabled
                                ? AppColors.textDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.favorite,
                            size: 14,
                            color: enabled
                                ? AppColors.primaryPink
                                : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          alarm.label.isEmpty
                              ? TimeFormatter.formatRepeatDays(
                                  alarm.repeatDays)
                              : alarm.label,
                          style: TextStyle(
                            color: enabled
                                ? AppColors.textMuted
                                : AppColors.textMuted.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (alarm.label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          TimeFormatter.formatRepeatDays(alarm.repeatDays),
                          style: TextStyle(
                            color: AppColors.textMuted.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
