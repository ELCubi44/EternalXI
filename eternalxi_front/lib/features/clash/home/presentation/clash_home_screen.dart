import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hub principal Clash — fondo instituto (Thiago + Miguel de espaldas).
///
/// Historia / Eventos viven en [ClashShellScreen] (overlay encima de la nav),
/// porque con `extendBody` la barra inferior interceptaba los toques.
class ClashHomeScreen extends StatefulWidget {
  const ClashHomeScreen({super.key, this.autoCheckService});

  final ClashSyncAutoCheckService? autoCheckService;

  static const backgroundAsset =
      'assets/images/clash/home/clash_home_bg_institute.png';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          ClashHomeScreen.backgroundAsset,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.08),
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFF0A1020),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.22, 0.55, 1.0],
              colors: [
                Color(0x66000000),
                Color(0x14000000),
                Color(0x28000000),
                Color(0x99000000),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
