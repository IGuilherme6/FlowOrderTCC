import 'package:floworder/view/TelaCaixa.dart';
import 'package:floworder/view/TelaCardapio.dart';
import 'package:floworder/view/TelaDashboard.dart';
import 'package:floworder/view/TelaDecisao.dart';
import 'package:floworder/view/TelaMesa.dart';
import 'package:floworder/view/TelaPedidos.dart';
import 'package:floworder/view/TelaRelatorios.dart';
import 'package:floworder/view/Tela_Cadastro.dart';
import 'package:floworder/view/Tela_CadastroUsuario.dart';
import 'package:floworder/view/Tela_Login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => TelaDecisao(),
        '/telaCadastro': (context) => Tela_Cadastro(),
        '/telalogin': (context) => Tela_Login(),
        '/funcionarios': (context) => TelaCadastroUsuario(),
        '/dashboard': (context) => TelaDashboard(),
        '/relatorios': (context) => TelaRelatorio(),
        '/pedidos': (context) => TelaPedidos(),
        '/caixa': (context) => TelaCaixa(),
        '/cardapio': (context) => TelaCardapio(),
        '/mesas': (context) => TelaMesa(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
