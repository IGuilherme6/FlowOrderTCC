import 'package:floworder/view/TelaDecisao.dart';
import 'package:floworder/view/Tela_Cadastro.dart';
import 'package:floworder/view/Tela_CadastroUsuario.dart';
import 'package:floworder/view/Tela_Login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      },
      debugShowCheckedModeBanner: false,
    );
  }

  }