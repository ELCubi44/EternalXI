import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_story_map_button.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hub principal Clash — fondo instituto (Thiago + Miguel de espaldas).
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
        // Velo: un poco más arriba para legibilidad de la cabecera; abajo para nav.
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
        // Botón Historia sobre el banco (mapa de historia).
        Align(
          alignment: const Alignment(0, 0.42),
          child: Padding(
            padding: EdgeInsets.fromLTRB(36, 0, 36, 56 + bottomInset * 0.2),
            child: const ClashHomeStoryMapButton(),
          ),
        ),
      ],
    );
  }
}
