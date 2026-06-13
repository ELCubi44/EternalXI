import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Redirige a login si no hay usuario en sesión (rutas protegidas Clash/modo).
String? redirectIfUnauthenticated(BuildContext context, GoRouterState state) {
  final user = context.read<AuthController>().currentUser;
  if (user == null) {
    return AppRoutes.login;
  }
  return null;
}
