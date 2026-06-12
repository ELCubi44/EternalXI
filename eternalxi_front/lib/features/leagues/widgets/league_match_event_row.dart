import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:eternal_xi/features/leagues/widgets/league_player_avatar.dart';
import 'package:flutter/material.dart';

enum LeagueMatchEventSide { local, away, neutral }

class LeagueMatchEventRow extends StatelessWidget {
  const LeagueMatchEventRow({
    super.key,
    required this.minuteLabel,
    required this.text,
    this.fallbackText = 'Evento',
    required this.side,
    this.player,
    this.playerOut,
    this.loanEventPhotoUri,
    this.neutralIcon,
    this.isLoanGrouped = false,
    this.isLoanIndividual = false,
    this.isSubstitution = false,
    this.substitutionPhotoInUri,
    this.substitutionPhotoOutUri,
    this.eventTypeIcon,
    this.eventTypeIconColor,
    this.eventTypeLeading,
  });

  final String minuteLabel;
  final String text;
  final String fallbackText;
  final LeagueMatchEventSide side;

  /// Jugador principal del evento (p. ej. entra en un CAMBIO).
  final LeagueSquadPlayer? player;

  /// Jugador secundario (p. ej. sale en un CAMBIO).
  final LeagueSquadPlayer? playerOut;

  /// Foto del cedido en cronología (`/assets/loan-players/{id}` o URL resuelta).
  final Uri? loanEventPhotoUri;

  /// Solo se usa en [LeagueMatchEventSide.neutral]; el texto sigue siendo el del backend.
  final IconData? neutralIcon;
  final bool isLoanGrouped;
  final bool isLoanIndividual;

  /// Sustitución: fila normal con dos fotos (sale → entra), sin tarjeta neutra.
  final bool isSubstitution;
  final Uri? substitutionPhotoInUri;
  final Uri? substitutionPhotoOutUri;

  /// Icono por tipo de evento (gol, tarjeta, lesión…); no se usa en CAMBIO (usa icono entre fotos).
  final IconData? eventTypeIcon;
  final Color? eventTypeIconColor;
  final Widget? eventTypeLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final minText = minuteLabel.trim();
    final bodyText = text.trim().isEmpty ? fallbackText : text.trim();
    String withMinutePrefix(String message) {
      if (minText.isEmpty) {
        return message;
      }
      return '$minText - $message';
    }

    if (isLoanGrouped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              neutralIcon ?? Icons.swap_horiz_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bodyText,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isSubstitution) {
      return _substitutionRow(
        context: context,
        theme: theme,
        colorScheme: colorScheme,
        minText: minText,
        bodyText: bodyText,
        withMinutePrefix: withMinutePrefix,
      );
    }

    if (isLoanIndividual) {
      final lead = _loanIndividualLead(
        context: context,
        player: player,
        loanUri: loanEventPhotoUri,
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          lead,
          const SizedBox(width: 6),
          if (_hasEventTypeIcon) ...[
            _eventTypeIcon(typeIconColor: _resolveTypeIconColor(colorScheme)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              withMinutePrefix(bodyText),
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final typeIconColor = _resolveTypeIconColor(colorScheme);

    switch (side) {
      case LeagueMatchEventSide.local:
        return _standardLeftAlignedPlayerRow(
          theme: theme,
          bodyText: bodyText,
          withMinutePrefix: withMinutePrefix,
          typeIconColor: typeIconColor,
        );
      case LeagueMatchEventSide.away:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                minText.isEmpty ? bodyText : '$bodyText - $minText',
                textAlign: TextAlign.right,
                softWrap: true,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_hasEventTypeIcon) ...[
              const SizedBox(width: 6),
              _eventTypeIcon(typeIconColor: typeIconColor),
            ],
            if (loanEventPhotoUri != null) ...[
              const SizedBox(width: 6),
              _TimelineCircleNetworkPhoto(uri: loanEventPhotoUri!, size: 34),
            ] else if (player != null) ...[
              const SizedBox(width: 6),
              LeaguePlayerAvatar(player: player!, size: 34, circular: true),
            ],
          ],
        );
      case LeagueMatchEventSide.neutral:
        final maxW = MediaQuery.sizeOf(context).width - 32;
        // Cedidos sin idLiga en plantilla → side neutral; misma fila que jugadores locales,
        // sin tarjeta de fondo (antes parecían “otro tipo” de evento).
        if (loanEventPhotoUri != null && !isLoanGrouped) {
          return _standardLeftAlignedPlayerRow(
            theme: theme,
            bodyText: bodyText,
            withMinutePrefix: withMinutePrefix,
            typeIconColor: typeIconColor,
          );
        }
        return Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW.clamp(120, 560)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (neutralIcon != null) ...[
                    Icon(neutralIcon, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      withMinutePrefix(bodyText),
                      textAlign: neutralIcon == null
                          ? TextAlign.center
                          : TextAlign.start,
                      softWrap: true,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
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

  /// Misma presentación que jugadas del equipo local (avatar + icono opcional + texto con minuto).
  Widget _standardLeftAlignedPlayerRow({
    required ThemeData theme,
    required String bodyText,
    required String Function(String) withMinutePrefix,
    required Color typeIconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (loanEventPhotoUri != null) ...[
          _TimelineCircleNetworkPhoto(uri: loanEventPhotoUri!, size: 34),
          const SizedBox(width: 6),
        ] else if (player != null) ...[
          LeaguePlayerAvatar(player: player!, size: 34, circular: true),
          const SizedBox(width: 6),
        ],
        if (_hasEventTypeIcon) ...[
          _eventTypeIcon(typeIconColor: typeIconColor),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            withMinutePrefix(bodyText),
            softWrap: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  bool get _hasEventTypeIcon =>
      eventTypeLeading != null || eventTypeIcon != null;

  Widget _eventTypeIcon({required Color typeIconColor}) {
    if (eventTypeLeading != null) {
      return eventTypeLeading!;
    }
    return Icon(
      eventTypeIcon,
      size: 22,
      color: typeIconColor,
    );
  }

  Color _resolveTypeIconColor(ColorScheme colorScheme) {
    if (eventTypeIconColor != null) {
      return eventTypeIconColor!;
    }
    if (eventTypeLeading != null || eventTypeIcon == Icons.report_rounded) {
      return colorScheme.error;
    }
    return colorScheme.primary;
  }

  Widget _substitutionRow({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String minText,
    required String bodyText,
    required String Function(String) withMinutePrefix,
  }) {
    const size = 34.0;
    final outFace = _timelineFace(
      context: context,
      uri: substitutionPhotoOutUri,
      player: playerOut,
      size: size,
    );
    final inFace = _timelineFace(
      context: context,
      uri: substitutionPhotoInUri,
      player: player,
      size: size,
    );
    final swap = Icon(
      Icons.swap_horiz_rounded,
      size: 22,
      color: colorScheme.primary,
    );
    final textWidget = Expanded(
      child: Text(
        withMinutePrefix(bodyText),
        softWrap: true,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.32,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    switch (side) {
      case LeagueMatchEventSide.local:
      case LeagueMatchEventSide.neutral:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            outFace,
            const SizedBox(width: 4),
            swap,
            const SizedBox(width: 4),
            inFace,
            const SizedBox(width: 8),
            textWidget,
          ],
        );
      case LeagueMatchEventSide.away:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            textWidget,
            const SizedBox(width: 8),
            inFace,
            const SizedBox(width: 4),
            swap,
            const SizedBox(width: 4),
            outFace,
          ],
        );
    }
  }

  Widget _timelineFace({
    required BuildContext context,
    required Uri? uri,
    required LeagueSquadPlayer? player,
    required double size,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (uri != null) {
      return _TimelineCircleNetworkPhoto(uri: uri, size: size);
    }
    if (player != null) {
      return LeaguePlayerAvatar(player: player, size: size, circular: true);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Avatar cedido (URL explícita), plantilla del roster, o icono genérico.
  static Widget _loanIndividualLead({
    required BuildContext context,
    required LeagueSquadPlayer? player,
    required Uri? loanUri,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (loanUri != null) {
      return _TimelineCircleNetworkPhoto(uri: loanUri, size: 34);
    }
    if (player != null) {
      return LeaguePlayerAvatar(player: player, size: 34, circular: true);
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.swap_horiz_rounded,
        size: 18,
        color: colorScheme.primary,
      ),
    );
  }
}

class _TimelineCircleNetworkPhoto extends StatelessWidget {
  const _TimelineCircleNetworkPhoto({required this.uri, required this.size});

  final Uri uri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
    final img = Image.network(
      uri.toString(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
    return ClipOval(child: img);
  }
}
