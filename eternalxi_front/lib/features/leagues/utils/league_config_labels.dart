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

  static String calendarLabel(bool? permiteEntresemana) {
    if (permiteEntresemana == null) {
      return '—';
    }
    if (permiteEntresemana) {
      return 'fines de semana + martes/miércoles';
    }
    return 'fines de semana';
  }

  static String formatLabel(bool? idaYVuelta) {
    if (idaYVuelta == null) {
      return '—';
    }
    return idaYVuelta ? 'Ida y vuelta' : 'Solo ida';
  }

  static String semanaPreviaLabel(bool? value) {
    if (value == null) {
      return '—';
    }
    return value ? 'Sí' : 'No';
  }

  static String recompensaJornadaLabel(int? pts) {
    if (pts == null) {
      return '—';
    }
    return '$pts pts/jornada';
  }

  static String dineroPorPuntoLabel(int? amount) {
    if (amount == null) {
      return '—';
    }
    return '${LeagueMoneyFormat.euros(amount.toDouble())}/punto';
  }

  static String dineroPorPuntoOptionLabel(int amount) {
    return '${LeagueMoneyFormat.euros(amount.toDouble())}/punto';
  }

  static String participantesCapLabel(int? max) {
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

  static List<LeagueConfigSummaryRow> summaryRows(LeagueDetail detail) {
    if (!detail.hasConfigSummary) {
      return const [];
    }
    return [
      LeagueConfigSummaryRow(
        label: 'Participantes',
        value: participantesCapLabel(detail.maxParticipantes),
      ),
      LeagueConfigSummaryRow(
        label: 'Calendario',
        value: calendarLabel(detail.permiteEntresemana),
      ),
      LeagueConfigSummaryRow(
        label: 'Formato',
        value: formatLabel(detail.idaYVuelta),
      ),
      LeagueConfigSummaryRow(
        label: 'Semana previa de fichajes',
        value: semanaPreviaLabel(detail.semanaPreviaFichajes),
      ),
      LeagueConfigSummaryRow(
        label: 'Recompensa',
        value: recompensaJornadaLabel(detail.recompensaBaseJornada),
      ),
      LeagueConfigSummaryRow(
        label: 'Dinero',
        value: dineroPorPuntoLabel(detail.dineroPorPuntoFantasy),
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
