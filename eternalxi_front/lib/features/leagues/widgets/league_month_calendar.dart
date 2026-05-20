import 'package:flutter/material.dart';

/// Calendario mensual con marcas en días con actividad y deslizamiento horizontal entre meses.
class LeagueMonthCalendar extends StatelessWidget {
  const LeagueMonthCalendar({
    super.key,
    required this.visibleMonth,
    required this.daysWithActivity,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final DateTime visibleMonth;
  final Set<DateTime> daysWithActivity;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;

  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  static DateTime _dateOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final leadingBlanks = (first.weekday + 6) % 7;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final today = _dateOnly(DateTime.now());

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _monthTitle(first),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca un día para ver partidos',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final w in _weekdayLabels)
                  Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.02,
              ),
              itemCount: totalCells,
              itemBuilder: (context, i) {
                final dayNum = i - leadingBlanks + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = DateTime(first.year, first.month, dayNum);
                final key = _dateOnly(day);
                final has = daysWithActivity.contains(key);
                final sel =
                    selectedDay != null && _dateOnly(selectedDay!) == key;
                final isToday = key == today;

                return _DayCell(
                  day: dayNum,
                  hasActivity: has,
                  selected: sel,
                  isToday: isToday,
                  onTap: () => onSelectDay(key),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _monthTitle(DateTime first) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[first.month - 1]} ${first.year}';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hasActivity,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool hasActivity;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bg;
    final Color fg;
    if (selected) {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
    } else if (isToday) {
      bg = colorScheme.primaryContainer.withValues(alpha: 0.85);
      fg = colorScheme.onPrimaryContainer;
    } else if (hasActivity) {
      bg = colorScheme.secondaryContainer.withValues(alpha: 0.55);
      fg = colorScheme.onSecondaryContainer;
    } else {
      bg = colorScheme.surface.withValues(alpha: 0.9);
      fg = colorScheme.onSurface;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : isToday
                  ? colorScheme.primary.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: isToday && !selected ? 1.5 : 1,
            ),
            boxShadow: [
              if (!selected && hasActivity)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              if (hasActivity)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
