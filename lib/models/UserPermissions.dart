import 'package:flutter/material.dart';

class UserPermissions {
  static const String GERENTE = 'Gerente';
  static const String ATENDENTE = 'Atendente';
  static const String COZINHEIRO = 'Cozinheiro';

  ///seta as permissoes dos users
  static Map<String, List<String>> permissions = {
    GERENTE: [
      '/dashboard',
      '/caixa',
      '/pedidos',
      '/cardapio',
      '/mesas',
      '/funcionarios',
      '/relatorios',
    ],
    ATENDENTE: [
      '/dashboard',
      '/caixa',
    ],
    COZINHEIRO: [
      '/pedidos',
      '/cardapio',
    ],
  };

  static bool hasAccess(String? userType, String route) {
    if (userType == null) return false;
    final userPermissions = permissions[userType];
    if (userPermissions == null) return false;
    return userPermissions.contains(route);
  }

  static List<String> getAllowedRoutes(String? userType) {
    if (userType == null) return [];
    return permissions[userType] ?? [];
  }

  static String getDefaultRoute(String? userType) {
    final allowedRoutes = getAllowedRoutes(userType);
    if (allowedRoutes.isEmpty) return '/home';
    return allowedRoutes.first;
  }

  static Map<String, Map<String, dynamic>> menuInfo = {
    '/dashboard': {'icon': Icons.dashboard, 'title': 'Dashboard'},
    '/caixa': {'icon': Icons.point_of_sale, 'title': 'Caixa'},
    '/pedidos': {'icon': Icons.fact_check_outlined, 'title': 'Pedidos'},
    '/cardapio': {'icon': Icons.menu_book, 'title': 'Cardápio'},
    '/mesas': {'icon': Icons.table_bar, 'title': 'Mesas'},
    '/funcionarios': {'icon': Icons.person, 'title': 'Funcionários'},
    '/relatorios': {'icon': Icons.analytics, 'title': 'Relatórios'},
  };
}