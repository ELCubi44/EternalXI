import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hub principal Clash (contenido pendiente; se irá añadiendo poco a poco).
class ClashHomeScreen extends StatefulWidget {
  const ClashHomeScreen({super.key, this.autoCheckService});

  final ClashSyncAutoCheckService? autoCheckService;

  @override
  State<ClashHomeScreen> createState() => _ClashHomeScreenState();
}

class _ClashHomeScreenState extends State<ClashHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _runAutoCheckIfEnabled(),
    );
  }

  Future<void> _runAutoCheckIfEnabled() async {
    if (!mounted) return;
    final service = widget.autoCheckService ?? _readAutoCheckService(context);
    if (service == null) return;
    await service.runIfEnabled();
  }

  ClashSyncAutoCheckService? _readAutoCheckService(BuildContext context) {
    try {
      return context.read<ClashSyncAutoCheckService>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClashScreenScaffold(
      title: context.l10n.clashTabHome,
      children: const [],
    );
  }
}
