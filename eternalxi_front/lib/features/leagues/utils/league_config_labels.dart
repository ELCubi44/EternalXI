import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/league_detail.dart';

/// Valores y etiquetas de configuración de liga (creación y detalle).
abstract final class LeagueConfigLabels {
  LeagueConfigLabels._();

  static const List<int> maxParticipantesOptions = [10, 12, 14, 16, 18, 20];
  static const List<int> dineroPorPuntoOptions = [100000, 200000, 300000];

  static const int recompensaMin = 300;
  static const int recompensaMax = 1000;
  static const int recompensaStep = 50;
  static const int recompensaDefault = 500;

  static const int maxParticipantesDefault = 12;
  static const int dineroPorPuntoDefault = 200000;

  static LeagueL10n? _ll(AppLocalizations? l10n) =>
      l10n != null ? LeagueL10n.fromL10n(l10n) : null;

  static String calendarLabel(
    bool? permiteEntresemana, {
    AppLocalizations? l10n,
  }) {
    final ll = _ll(l10n);
    if (permiteEntresemana == null) {
      return '—';
    }
    if (permiteEntresemana) {
      return ll?.calendarWithMidweek ?? 'fines de semana + martes/miércoles';
    }
    return ll?.calendarWeekendsOnly ?? 'fines de semana';
  }

  static String formatLabel(bool? idaYVuelta, {AppLocalizations? l10n}) {
    final ll = _ll(l10n);
    if (idaYVuelta == null) {
      return '—';
    }
    return idaYVuelta
        ? (ll?.roundTrip ?? 'Ida y vuelta')
        : (ll?.singleLeg ?? 'Solo ida');
  }

  static String semanaPreviaLabel(bool? value, {AppLocalizations? l10n}) {
    final ll = _ll(l10n);
    if (value == null) {
      return '—';
    }
    return value ? (ll?.yesWord ?? 'Sí') : (ll?.noWord ?? 'No');
  }

  static String recompensaJornadaLabel(int? pts, {AppLocalizations? l10n}) {
    final ll = _ll(l10n);
    if (pts == null) {
      return '—';
    }
    return ll?.minRewardPts(pts) ?? 'Mín. $pts fichas (último puesto)';
  }

  /// Reparto descendente: mínimo + 50 fichas por cada puesto que sube.
  static int rewardForRank({
    required int rank,
    required int participantCount,
    required int minReward,
  }) {
    if (participantCount < 1) {
      return minReward;
    }
    final safeRank = rank.clamp(1, participantCount);
    return minReward + (participantCount - safeRank) * recompensaStep;
  }

  static String rewardDistributionPreview({
    required int minReward,
    required int participantCount,
    AppLocalizations? l10n,
  }) {
    final ll = _ll(l10n);
    if (participantCount < 1) {
      return '—';
    }
    final first = rewardForRank(
      rank: 1,
      participantCount: participantCount,
      minReward: minReward,
    );
    if (participantCount == 1) {
      return '$first fichas';
    }
    final second = rewardForRank(
      rank: 2,
      participantCount: participantCount,
      minReward: minReward,
    );
    return ll?.rewardDistributionPreview('$first', '$second', minReward) ??
        '$first, $second, …, $minReward fichas/jornada';
  }

  static String dineroPorPuntoLabel(int? amount, {AppLocalizations? l10n}) {
    final ll = _ll(l10n);
    if (amount == null) {
      return '—';
    }
    final formatted = LeagueMoneyFormat.euros(amount.toDouble());
    return ll?.perPoint(formatted) ?? '$formatted/punto';
  }

  static String dineroPorPuntoOptionLabel(int amount, {AppLocalizations? l10n}) {
    return dineroPorPuntoLabel(amount, l10n: l10n);
  }

  static String participantesCapLabel(int? max, {AppLocalizations? l10n}) {
    if (max == null) {
      return '—';
    }
    return '$max';
  }

  /// `DD/MM a las HH:mm` en hora local.
  static String formatLeagueStart(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month a las $hour:$minute';
  }

  static List<LeagueConfigSummaryRow> summaryRows(
    LeagueDetail detail, {
    AppLocalizations? l10n,
  }) {
    final ll = _ll(l10n);
    if (!detail.hasConfigSummary) {
      return const [];
    }
    return [
      LeagueConfigSummaryRow(
        label: ll?.configParticipants ?? 'Participantes',
        value: participantesCapLabel(detail.maxParticipantes, l10n: l10n),
      ),
      LeagueConfigSummaryRow(
        label: ll?.configCalendar ?? 'Calendario',
        value: calendarLabel(detail.permiteEntresemana, l10n: l10n),
      ),
      LeagueConfigSummaryRow(
        label: ll?.configFormat ?? 'Formato',
        value: formatLabel(detail.idaYVuelta, l10n: l10n),
      ),
      LeagueConfigSummaryRow(
        label: ll?.configSigningWeek ?? 'Semana previa de fichajes',
        value: semanaPreviaLabel(detail.semanaPreviaFichajes, l10n: l10n),
      ),
      LeagueConfigSummaryRow(
        label: ll?.configMatchdayReward ?? 'Recompensa jornada',
        value: recompensaJornadaLabel(detail.recompensaBaseJornada, l10n: l10n),
      ),
      LeagueConfigSummaryRow(
        label: ll?.configMoney ?? 'Dinero',
        value: dineroPorPuntoLabel(detail.dineroPorPuntoFantasy, l10n: l10n),
      ),
    ];
  }
}

class LeagueConfigSummaryRow {
  const LeagueConfigSummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
