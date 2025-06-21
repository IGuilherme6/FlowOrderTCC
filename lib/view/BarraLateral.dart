import 'package:flutter/material.dart';

class Barralateral extends StatelessWidget {
  final String currentRoute;
  final Function(String) onItemTapped;

  const Barralateral({
    Key? key,
    required this.currentRoute,
    required this.onItemTapped,
  }) : super(key: key);

  // Cores definidas
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color lightRed = Color(0xFFEF4444);
  static const Color backgroundBlack = Color(0xFF111827);
  static const Color cardBlack = Color(0xFF1F2937);
  static const Color textWhite = Color(0xFFF9FAFB);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color borderGray = Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: cardBlack,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkRed,
              boxShadow: [
                BoxShadow(
                  color: primaryRed.withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset(
                  'logo/Icone_FlowOrder.png',
                  height: 100,
                  width: double.infinity,
                ),
              ],
            ),
          ),
          // Menu Items
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  icon: Icons.build,
                  title: 'Pedidos',
                  route: '/pedidos',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  icon: Icons.menu_book,
                  title: 'Cardápio',
                  route: '/cardapio',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'Funcionários',
                  route: '/funcionarios',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: 'Relatórios',
                  route: '/relatorios',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? primaryRed : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? textWhite : textGray,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? textWhite : textGray,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => onItemTapped(route),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}