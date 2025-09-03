import 'package:firebase_auth/firebase_auth.dart';
import 'package:floworder/view/TelaHome.dart';
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return TelaHome(); // usuário logado
        } else {
          return Tela_Login(); // usuário não logado
        }
      },
    );
  }
}
