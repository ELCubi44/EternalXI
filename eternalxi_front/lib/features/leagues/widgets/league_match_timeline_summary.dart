import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/league_match_event.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_display_phase.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_event_importance.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_event_l10n.dart';
import 'package:eternal_xi/features/leagues/utils/league_match_visible_state.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_event_row.dart';
import 'package:eternal_xi/features/leagues/widgets/league_match_timeline_tab.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:eternal_xi/shared/widgets/player_injury_icon.dart';
import 'package:eternal_xi/shared/widgets/red_card_icon.dart';
import 'package:flutter/material.dart';

sealed class _SummaryEntry {
  const _SummaryEntry();
}

class _PhaseEntry extends _SummaryEntry {
  const _PhaseEntry(this.event);
  final LeagueMatchEvent event;
}

class _HighlightEntry extends _SummaryEntry {
  const _HighlightEntry(this.event);
  final LeagueMatchEvent event;
}

class _MinorGroupEntry extends _SummaryEntry {
  const _MinorGroupEntry(this.events);
  final List<LeagueMatchEvent> events;
}

/// Cronolog�a con resumen visual (vivo y finalizado): progreso y l�nea central.
class LeagueMatchTimelineSummary extends StatefulWidget {
  const LeagueMatchTimelineSummary({
    super.key,
    required this.roster,
    required this.events,
    required this.ll,
    this.phase = LeagueMatchDisplayPhase.finished,
    this.scoreLocal = 0,
    this.scoreVisitante = 0,
    this.liveMinuteLabel,
    this.localTeamName = '',
    this.awayTeamName = '',
  });

  final LeagueMatchRoster roster;
  final List<LeagueMatchEvent> events;
  final LeagueL10n ll;
  final LeagueMatchDisplayPhase phase;
  final int scoreLocal;
  final int scoreVisitante;
  final String? liveMinuteLabel;
  final String localTeamName;
  final String awayTeamName;

  @override
  State<LeagueMatchTimelineSummary> createState() =>
      _LeagueMatchTimelineSummaryState();
}

class _LeagueMatchTimelineSummaryState extends State<LeagueMatchTimelineSummary>
    with SingleTickerProviderStateMixin {
  int _seenEventCount = 0;
  late AnimationController _livePulse;

  @override
  void initState() {
    super.initState();
    _seenEventCount = widget.events.length;
    _livePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.phase == LeagueMatchDisplayPhase.live) {
      _livePulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LeagueMatchTimelineSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phase == LeagueMatchDisplayPhase.live) {
      if (!_livePulse.isAnimating) {
        _livePulse.repeat(reverse: true);
      }
    } else {
      _livePulse.stop();
    }
  }

  @override
  void dispose() {
    _livePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordered = [...widget.events]..sort(compareLeagueMatchEventsChrono);
    if (ordered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Text(
          widget.ll.noMatchEventsYet,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final isLive = widget.phase == LeagueMatchDisplayPhase.live;
    final newEventStartIndex =
        isLive && widget.events.length > _seenEventCount
            ? ordered.length - (widget.events.length - _seenEventCount)
            : -1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.events.length != _seenEventCount) {
        setState(() => _seenEventCount = widget.events.length);
      }
    });

    final entries = _buildEntries(ordered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLive) _LiveStrip(pulse: _livePulse, ll: widget.ll),
        _MatchProgressBar(
          events: ordered,
          phase: widget.phase,
          liveMinuteLabel: widget.liveMinuteLabel,
          scoreLocal: widget.scoreLocal,
          scoreVisitante: widget.scoreVisitante,
          localName: widget.localTeamName,
          awayName: widget.awayTeamName,
        ),
        const SizedBox(height: 14),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: entries.length,
          separatorBuilder: (_, i) {
            final next = entries[i + 1];
            if (next is _PhaseEntry || entries[i] is _PhaseEntry) {
              return const SizedBox(height: 14);
            }
            return const SizedBox(height: 8);
          },
          itemBuilder: (context, i) {
            final entry = entries[i];
            final animateIn = newEventStartIndex >= 0 &&
                i >= newEventStartIndex.clamp(0, entries.length);
            return _AnimatedEntry(
              key: ValueKey(_entryKey(entry, i)),
              animate: animateIn,
              child: _buildEntry(context, entry, i),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _entryKey(_SummaryEntry entry, int index) {
    return switch (entry) {
      _PhaseEntry(:final event) => 'p-${event.idEvento}',
      _HighlightEntry(:final event) => 'h-${event.idEvento}',
      _MinorGroupEntry(:final events) =>
        'm-${events.first.idEvento}-${events.length}',
    };
  }

  List<_SummaryEntry> _buildEntries(List<LeagueMatchEvent> ordered) {
    final out = <_SummaryEntry>[];
    var minorBuf = <LeagueMatchEvent>[];

    void flushMinor() {
      if (minorBuf.isEmpty) {
        return;
      }
      out.add(_MinorGroupEntry(List.of(minorBuf)));
      minorBuf = [];
    }

    for (final e in ordered) {
      if (shouldSuppressAssistInSummary(ordered, e)) {
        continue;
      }
      final kind = classifyLeagueMatchEventImportance(e);
      if (kind == LeagueMatchEventImportance.phase) {
        flushMinor();
        out.add(_PhaseEntry(e));
      } else if (kind == LeagueMatchEventImportance.highlight) {
        flushMinor();
        out.add(_HighlightEntry(e));
      } else {
        minorBuf.add(e);
      }
    }
    flushMinor();
    return out;
  }

  Widget _buildEntry(BuildContext context, _SummaryEntry entry, int index) {
    return switch (entry) {
      _PhaseEntry(:final event) => _PhaseMarker(
          event: event,
          ll: widget.ll,
        ),
      _HighlightEntry(:final event) =>
        _timelineRowForHighlight(context, event),
      _MinorGroupEntry(:final events) => _MinorPlaysExpansion(
          events: events,
          roster: widget.roster,
          playersById: widget.roster.playersById,
          ll: widget.ll,
        ),
    };
  }

  Widget _timelineRowForHighlight(BuildContext context, LeagueMatchEvent event) {
    if (leagueMatchEventTipoCambioSustitucion(event) ||
        isLoanGroupedEvent(event)) {
      return LeagueMatchTimelineTab.rowForEvent(
        event,
        widget.roster,
        widget.roster.playersById,
        widget.ll,
      );
    }
    return _SpineHighlightRow(
      event: event,
      ordered: widget.events,
      roster: widget.roster,
      playersById: widget.roster.playersById,
      ll: widget.ll,
    );
  }
}

class _LiveStrip extends StatelessWidget {
  const _LiveStrip({required this.pulse, required this.ll});

  final Animation<double> pulse;
  final LeagueL10n ll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  XiColors.heroRed.withValues(alpha: 0.12 + pulse.value * 0.08),
                  XiColors.royalBlue.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: XiColors.heroRed.withValues(alpha: 0.35 + pulse.value * 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 18,
                  color: XiColors.heroRed.withValues(alpha: 0.85 + pulse.value * 0.15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ll.timelineLiveUpdating,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: XiColors.heroRed,
                          letterSpacing: 0.3,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MatchProgressBar extends StatelessWidget {
  const _MatchProgressBar({
    required this.events,
    required this.phase,
    required this.scoreLocal,
    required this.scoreVisitante,
    required this.localName,
    required this.awayName,
    this.liveMinuteLabel,
  });

  final List<LeagueMatchEvent> events;
  final LeagueMatchDisplayPhase phase;
  final int scoreLocal;
  final int scoreVisitante;
  final String localName;
  final String awayName;
  final String? liveMinuteLabel;

  int _currentMinute() {
    if (phase == LeagueMatchDisplayPhase.live && liveMinuteLabel != null) {
      final digits = RegExp(r'\d+').stringMatch(liveMinuteLabel!);
      return int.tryParse(digits ?? '') ?? 0;
    }
    if (events.isEmpty) {
      return 0;
    }
    return events.map((e) => e.minuto).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minute = _currentMinute().clamp(0, 90);
    final progress = minute / 90.0;
    final goals = events.where(isGoalMatchEvent).toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localName.isEmpty ? '�' : localName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    ),
                ),
              ),
              Text(
                '$scoreLocal - $scoreVisitante',
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 1.2,
                ),
              ),
              Expanded(
                child: Text(
                  awayName.isEmpty ? '�' : awayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.02, 1.0),
                      minHeight: 8,
                      backgroundColor:
                          context.xiDivider.withValues(alpha: 0.45),
                      valueColor: AlwaysStoppedAnimation(
                        phase == LeagueMatchDisplayPhase.live
                            ? XiColors.techCyan
                            : XiColors.royalBlue,
                      ),
                    ),
                  ),
                  for (final g in goals)
                    Positioned(
                      left: (g.minuto.clamp(0, 90) / 90.0 * w) - 5,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: XiColors.classicGold,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.xiBackground,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: XiColors.classicGold.withValues(alpha: 0.45),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatLeagueMatchMinuteLabel(0), style: theme.textTheme.labelSmall),
              Text(
                phase == LeagueMatchDisplayPhase.live
                    ? (liveMinuteLabel ?? formatLeagueMatchMinuteLabel(minute))
                    : formatLeagueMatchMinuteLabel(90),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: phase == LeagueMatchDisplayPhase.live
                      ? XiColors.techCyan
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventVisualStyle {
  const _EventVisualStyle({
    required this.gradient,
    required this.border,
    required this.shadow,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final List<Color> gradient;
  final Color border;
  final Color shadow;
  final IconData icon;
  final Color iconColor;
  final String label;
}

_EventVisualStyle _eventVisualStyle(LeagueMatchEvent e) {
  if (isGoalMatchEvent(e)) {
    return const _EventVisualStyle(
      gradient: [Color(0xFF1F6B46), Color(0xFF123B31)],
      border: Color(0x6641B978),
      shadow: XiColors.emeraldGreen,
      icon: Icons.sports_soccer,
      iconColor: XiColors.classicGold,
      label: 'Gol',
    );
  }
  if (isRedCardMatchEvent(e)) {
    return const _EventVisualStyle(
      gradient: [Color(0xFF8E1F2D), Color(0xFF5C1210)],
      border: Color(0x66D93632),
      shadow: XiColors.heroRed,
      icon: Icons.square_rounded,
      iconColor: XiColors.heroRed,
      label: 'Roja',
    );
  }
  final t = normalizedLeagueMatchEventType(e);
  if (t.contains('PARADA')) {
    return const _EventVisualStyle(
      gradient: [Color(0xFF173A63), Color(0xFF2457C5)],
      border: Color(0x6630D6E8),
      shadow: XiColors.techCyan,
      icon: Icons.back_hand_outlined,
      iconColor: XiColors.techCyan,
      label: 'Parada',
    );
  }
  if (leagueMatchEventTipoCambioSustitucion(e)) {
    return const _EventVisualStyle(
      gradient: [Color(0xFF2A1848), Color(0xFF4B2E83)],
      border: Color(0x669D6BFF),
      shadow: XiColors.accentViolet,
      icon: Icons.swap_horiz_rounded,
      iconColor: XiColors.accentViolet,
      label: 'Cambio',
    );
  }
  return const _EventVisualStyle(
    gradient: [Color(0xFF1C2E52), Color(0xFF152240)],
    border: Color(0x558FD9FF),
    shadow: XiColors.royalBlue,
    icon: Icons.star_rounded,
    iconColor: XiColors.iceBlue,
    label: 'Jugada',
  );
}

class _PhaseMarker extends StatelessWidget {
  const _PhaseMarker({required this.event, required this.ll});

  final LeagueMatchEvent event;
  final LeagueL10n ll;

  @override
  Widget build(BuildContext context) {
    final text = localizedMatchEventText(ll, event);
    return Row(
      children: [
        Expanded(child: Divider(color: context.xiDivider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.xiSurfaceInset,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.xiDivider),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        ),
        Expanded(child: Divider(color: context.xiDivider)),
      ],
    );
  }
}

class _SpineHighlightRow extends StatelessWidget {
  const _SpineHighlightRow({
    required this.event,
    required this.ordered,
    required this.roster,
    required this.playersById,
    required this.ll,
  });

  final LeagueMatchEvent event;
  final List<LeagueMatchEvent> ordered;
  final LeagueMatchRoster roster;
  final Map<int, LeagueSquadPlayer> playersById;
  final LeagueL10n ll;

  @override
  Widget build(BuildContext context) {
    final side = LeagueMatchTimelineTab.resolveSide(event, roster);
    final style = _eventVisualStyle(event);
    final player = playersById[event.idLigaJugadorPrincipal];
    final text = localizedMatchEventText(ll, event);
    final assist = isGoalMatchEvent(event)
        ? assistPlayerNameForGoal(ordered, event)
        : null;

    final isLocal = side == LeagueMatchEventSide.local;
    final isAway = side == LeagueMatchEventSide.away;

    Widget bubble({required bool mirror}) {
      final children = <Widget>[
        if (!mirror && player != null) ...[
          LeaguePlayerAvatar(player: player, size: 30, circular: true),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                mirror ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRedCardMatchEvent(event))
                    const RedCardIcon(size: 16)
                  else if (isInjuryMatchEvent(event))
                    const PlayerInjuryIcon(size: 16)
                  else
                    Icon(style.icon, size: 16, color: style.iconColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      textAlign: mirror ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            height: 1.25,
                          ),
                    ),
                  ),
                ],
              ),
              if (assist != null) ...[
                const SizedBox(height: 3),
                Text(
                  ll.timelineAssistBy(assist),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                ),
              ],
            ],
          ),
        ),
        if (mirror && player != null) ...[
          const SizedBox(width: 6),
          LeaguePlayerAvatar(player: player, size: 30, circular: true),
        ],
      ];
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                style.gradient.map((c) => c.withValues(alpha: 0.92)).toList(),
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: mirror ? children.reversed.toList() : children,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: isLocal || side == LeagueMatchEventSide.neutral
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: bubble(mirror: false),
                )
              : const SizedBox.shrink(),
        ),
        _MinuteSpine(minute: event.minuto, color: style.iconColor),
        Expanded(
          child: isAway
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: bubble(mirror: true),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MinuteSpine extends StatelessWidget {
  const _MinuteSpine({required this.minute, required this.color});

  final int minute;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          Container(
            width: 2,
            height: 8,
            color: context.xiDivider,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: context.xiCardSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.55)),
            ),
            child: Text(
              formatLeagueMatchMinuteLabel(minute),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
          Expanded(
            child: Container(width: 2, height: 12, color: context.xiDivider),
          ),
        ],
      ),
    );
  }
}

class _MinorPlaysExpansion extends StatefulWidget {
  const _MinorPlaysExpansion({
    required this.events,
    required this.roster,
    required this.playersById,
    required this.ll,
  });

  final List<LeagueMatchEvent> events;
  final LeagueMatchRoster roster;
  final Map<int, LeagueSquadPlayer> playersById;
  final LeagueL10n ll;

  @override
  State<_MinorPlaysExpansion> createState() => _MinorPlaysExpansionState();
}

class _MinorPlaysExpansionState extends State<_MinorPlaysExpansion> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final from = widget.events.first.minuto;
    final to = widget.events.last.minuto;
    return Column(
      children: [
        Material(
          color: context.xiSurfaceInset.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: context.xiTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.ll.timelineMinorPlays(
                        widget.events.length,
                        from,
                        to,
                      ),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: context.xiTextSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          for (final e in widget.events)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: LeagueMatchTimelineTab.rowForEvent(
                e,
                widget.roster,
                widget.playersById,
                widget.ll,
              ),
            ),
        ],
      ],
    );
  }
}

class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({
    super.key,
    required this.child,
    required this.animate,
  });

  final Widget child;
  final bool animate;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.animate ? const Offset(0, 0.08) : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

extension _StringEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
