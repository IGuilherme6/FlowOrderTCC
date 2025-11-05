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
import 'package:provider/provider.dart';


import '../auxiliar/Cores.dart';
import '../models/GlobalUser.dart';
import '../models/UserPermissions.dart';
import 'TelaMesa.dart';

class Barralateral extends StatelessWidget {
  final String currentRoute;

  const Barralateral({Key? key, required this.currentRoute}) : super(key: key);

  Future<void> logout() async {
    LoginFirebase loginFirebase = LoginFirebase();
    await loginFirebase.logout();
    globalUser.clearUserData(); // Limpar dados globais
  }

  @override
  Widget build(BuildContext context) {
    // Obter rotas permitidas para o tipo de usuário GLOBAL
    final allowedRoutes = UserPermissions.getAllowedRoutes(context.watch<GlobalUser>().userType);
    // ✅ Se ainda não carregou os dados do usuário, não monta a barra
    if (context.watch<GlobalUser>().userType == null || globalUser.userName == null) {
      return Container(
        width: 250,
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }


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
                SizedBox(height: 10),
                // Mostrar tipo de usuário GLOBAL
                if (globalUser.userType != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Cores.textGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      globalUser.userType!,
                      style: TextStyle(
                        color: Cores.darkRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Mostrar nome do usuário GLOBAL
                if (globalUser.userName != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      globalUser.userName!,
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Menu Items - Apenas itens permitidos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                // Gerar menu items dinamicamente baseado nas permissões
                ...allowedRoutes.map((route) {
                  final menuData = UserPermissions.menuInfo[route];
                  if (menuData == null) return SizedBox.shrink();

                  return Column(
                    children: [
                      _buildMenuItem(
                        context: context,
                        icon: menuData['icon'] as IconData,
                        title: menuData['title'] as String,
                        route: route,
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          // Botão de logout
          Container(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.logout, color: Cores.textGray, size: 20),
              title: Text(
                'Deslogar',
                style: TextStyle(
                  color: Cores.textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              onTap: () async {
                await logout();
                Navigator.pushReplacementNamed(context, '/telalogin');
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
    // Verificar se o usuário tem permissão para acessar a rota (usando variável global)
    if (!UserPermissions.hasAccess(globalUser.userType, routeName) && routeName != '/home') {
      // Mostrar mensagem de acesso negado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você não tem permissão para acessar esta página'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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
        return TelaRelatorios();
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