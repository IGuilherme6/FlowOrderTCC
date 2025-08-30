import 'dart:ui' as html;

import 'package:floworder/firebase/LoginFirebase.dart';
import 'package:floworder/view/TelaHome.dart';
import 'package:flutter/material.dart';
import 'package:floworder/view/TelaCaixa.dart';
import 'package:floworder/view/TelaCardapio.dart';
import 'package:floworder/view/TelaDashboard.dart';
import 'package:floworder/view/TelaPedidos.dart';
import 'package:floworder/view/TelaRelatorios.dart';
import 'package:floworder/view/Tela_CadastroUsuario.dart';

import '../auxiliar/Cores.dart';
import 'TelaMesa.dart';

class Barralateral extends StatelessWidget {
  final String currentRoute;

  const Barralateral({Key? key, required this.currentRoute}) : super(key: key);

  Future<void> logout() async {
    LoginFirebase loginFirebase = LoginFirebase();
    loginFirebase.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: Cores.cardBlack,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Cores.darkRed,
              boxShadow: [
                BoxShadow(
                  color: Cores.primaryRed.withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    navigateWithFade(context, '/home');
                  },
                  child: Image.asset(
                    'logo/Icone_FlowOrder.png',
                    height: 100,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.point_of_sale,
                  title: 'Caixa',
                  route: '/caixa',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.fact_check_outlined,
                  title: 'Pedidos',
                  route: '/pedidos',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.menu_book,
                  title: 'Cardápio',
                  route: '/cardapio',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.table_bar,
                  title: 'Mesas',
                  route: '/mesas',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Funcionários',
                  route: '/funcionarios',
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Relatórios',
                  route: '/relatorios',
                ),
              ],
            ),
          ),
          Container(
            //botão de sair
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.logout, color: Cores.textGray, size: 20),
              title: Text(
                'Deslogar/Logout',
                style: TextStyle(
                  color: Cores.textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              onTap: () async {
                Navigator.pushReplacementNamed(context, '/telalogin');
                await logout();
              },
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Função que faz a navegação com transição fade
  void navigateWithFade(BuildContext context, String routeName) {
    if (ModalRoute.of(context)?.settings.name == routeName) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) =>
            getPageForRoute(routeName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  // Mapeamento das rotas para as telas
  Widget getPageForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return TelaDashboard();
      case '/caixa':
        return TelaCaixa();
      case '/pedidos':
        return TelaPedidos();
      case '/mesas':
        return TelaMesa();
      case '/cardapio':
        return TelaCardapio();
      case '/funcionarios':
        return TelaCadastroUsuario();
      case '/relatorios':
        return TelaRelatorio();
      default:
        return TelaHome();
    }
  }

  // Criação dos itens do menu
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Cores.primaryRed : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Cores.textWhite : Cores.textGray,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Cores.textWhite : Cores.textGray,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => navigateWithFade(context, route),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
