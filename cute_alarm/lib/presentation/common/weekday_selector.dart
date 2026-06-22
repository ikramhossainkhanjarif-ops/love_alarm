import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class WeekdaySelector extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final dayNum = AppConstants.weekdayNumbers[i];
        final label = AppConstants.weekdayShortLabels[i];
        final isSelected = selected.contains(dayNum);
        return GestureDetector(
          onTap: () {
            final updated = Set<int>.from(selected);
            if (isSelected) {
              updated.remove(dayNum);
            } else {
              updated.add(dayNum);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryPink : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label.substring(0, 2),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}
