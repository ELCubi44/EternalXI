import 'package:eternal_xi/app/localization/l10n_extension.dart';

import 'package:eternal_xi/app/routes.dart';

import 'package:eternal_xi/app/theme/xi_theme_extension.dart';

import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';



/// Accesos principales: Cadena XI, equipo e invocaciones.

class ClashHomePrimaryActionGrid extends StatelessWidget {

  const ClashHomePrimaryActionGrid({super.key});



  void _goToTab(BuildContext context, int tabIndex) {

    context.read<ClashNavigationController>().selectTab(tabIndex);

    final router = GoRouter.maybeOf(context);

    if (router != null) {

      final path = GoRouterState.of(context).uri.path;

      if (path != AppRoutes.clash) {

        context.go(AppRoutes.clash);

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    final l10n = context.l10n;



    final actions = <_PrimaryAction>[

      _PrimaryAction(

        icon: Icons.link_rounded,

        title: l10n.clashHomeChallenges,

        description: l10n.clashHomePrimaryChallengesDesc,

        onTap: () => context.push(AppRoutes.clashTrials),

      ),

      _PrimaryAction(

        icon: Icons.groups_rounded,

        title: l10n.clashTabTeam,

        description: l10n.clashHomePrimaryTeamDesc,

        onTap: () => _goToTab(context, 1),

      ),

      _PrimaryAction(

        icon: Icons.auto_awesome_rounded,

        title: l10n.clashTabSummon,

        description: l10n.clashHomePrimarySummonDesc,

        onTap: () => _goToTab(context, 2),

      ),

    ];



    return GridView.builder(

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount: 2,

        mainAxisSpacing: 10,

        crossAxisSpacing: 10,

        childAspectRatio: 1.35,

      ),

      itemCount: actions.length,

      itemBuilder: (context, index) =>

          _PrimaryActionTile(action: actions[index]),

    );

  }

}



class _PrimaryAction {

  const _PrimaryAction({

    required this.icon,

    required this.title,

    required this.description,

    this.onTap,

  });



  final IconData icon;

  final String title;

  final String description;

  final VoidCallback? onTap;

}



class _PrimaryActionTile extends StatelessWidget {

  const _PrimaryActionTile({required this.action});



  final _PrimaryAction action;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);



    return Material(

      color: context.xiCardSurface,

      elevation: 0,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(16),

        side: BorderSide(color: context.xiDivider),

      ),

      clipBehavior: Clip.antiAlias,

      child: InkWell(

        onTap: action.onTap,

        child: Padding(

          padding: const EdgeInsets.all(12),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Icon(action.icon, color: theme.colorScheme.primary),

              const Spacer(),

              Text(

                action.title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: theme.textTheme.titleSmall?.copyWith(

                  color: context.xiTextPrimary,

                ),

              ),

              const SizedBox(height: 4),

              Text(

                action.description,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: theme.textTheme.bodySmall?.copyWith(

                  color: context.xiTextSecondary,

                  height: 1.25,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


