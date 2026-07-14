import 'package:eternal_xi/app/localization/l10n_extension.dart';

import 'package:eternal_xi/app/routes.dart';

import 'package:eternal_xi/app/theme/xi_theme_extension.dart';

import 'package:eternal_xi/features/clash/challenges/presentation/widgets/clash_trials_home_card.dart';

import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_header.dart';

import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_primary_action_grid.dart';

import 'package:eternal_xi/features/clash/home/presentation/widgets/clash_home_section_title.dart';

import 'package:eternal_xi/features/clash/sync/data/clash_sync_auto_check_service.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



/// Hub principal del modo Clash (Cadena XI + equipo + invocaciones).

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

    if (mounted) setState(() {});

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

    final l10n = context.l10n;



    return Material(

      color: Colors.transparent,

      child: ListView(

        physics: const BouncingScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),

        children: [

          const ClashHomeHeader(),

          const SizedBox(height: 20),

          ClashHomeSectionTitle(l10n.clashHomePlaySection),

          const ClashHomePrimaryActionGrid(),

          const SizedBox(height: 12),

          const ClashTrialsHomeCard(),

        ],

      ),

    );

  }

}


