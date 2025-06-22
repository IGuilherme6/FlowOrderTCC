import 'package:firebase_auth/firebase_auth.dart';
import 'package:floworder/view/Tela_CadastroUsuario.dart';
import 'package:floworder/view/Tela_Login.dart';
import 'package:flutter/material.dart';


class TelaDecisao extends StatelessWidget {

  const TelaDecisao({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Verifica conexão com Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            ),
          );
        }

        // Se o usuário está logado, manda para TelaHome
        if (snapshot.hasData) {
          return TelaCadastroUsuario();
        }

        // Se não está logado, manda para TelaLogin
        return Tela_Login();
      },
    );
  }
}
