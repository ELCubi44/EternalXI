import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.xiHeaderGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    XiColors.royalBlue.withValues(alpha: context.isXiDark ? 0.18 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    XiColors.classicGold.withValues(alpha: context.isXiDark ? 0.08 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leading != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: leading!,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: context.isXiDark
                                          ? const [
                                              Color(0xFF2A3F6A),
                                              XiColors.navyBlue,
                                            ]
                                          : const [
                                              Color(0xFFFFF8EC),
                                              XiColors.warmWhite,
                                            ],
                                    ),
                                    border: Border.all(
                                      color: XiColors.classicGold.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: XiColors.classicGold.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'XI',
                                      style: TextStyle(
                                        fontFamily: 'Lumiare',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: XiColors.classicGold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'ETERNAL XI',
                                  style: TextStyle(
                                    fontFamily: 'Lumiare',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: XiColors.classicGold,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: XiColors.royalBlue,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: XiColors.royalBlue.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: context.xiTextPrimary,
                                height: 1.1,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 13,
                                color: context.xiTextPrimary,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: context.xiCompactCardGradient,
                      ),
                      border: Border.all(color: context.xiBorderSubtle),
                      boxShadow: context.xiCardShadow,
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shell para formularios de cuenta dentro de la app (cambio nickname/correo).
class AccountFormShell extends StatelessWidget {
  const AccountFormShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.hint,
    this.currentValueLabel,
    this.currentValue,
  });

  final String title;
  final String? subtitle;
  final String? hint;
  final String? currentValueLabel;
  final String? currentValue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(color: context.xiBackground),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: context.xiBackground,
            surfaceTintColor: Colors.transparent,
            foregroundColor: context.xiTextPrimary,
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontWeight: FontWeight.w800,
                color: context.xiTextPrimary,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Lumiare',
                        fontSize: 13,
                        color: context.xiTextPrimary,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: context.xiCompactCardGradient,
                      ),
                      border: Border.all(color: context.xiBorderSubtle),
                      boxShadow: context.xiCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hint != null && hint!.trim().isNotEmpty) ...[
                          Text(
                            hint!,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 13,
                              color: context.xiTextPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if ((currentValue ?? '').trim().isNotEmpty) ...[
                          if (currentValueLabel != null)
                            Text(
                              currentValueLabel!,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: context.xiAccentText,
                                letterSpacing: 0.8,
                              ),
                            ),
                          if (currentValueLabel != null)
                            const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: context.xiSurfaceInset.withValues(
                                alpha: 0.55,
                              ),
                              border: Border.all(color: context.xiBorderSubtle),
                            ),
                            child: Text(
                              currentValue!.trim(),
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.xiTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        child,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
