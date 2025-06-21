
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioController {
  final CollectionReference _usuariosRef =
  FirebaseFirestore.instance.collection('usuarios');

  Future<String> cadastrarUsuario(Usuario usuario) async {
    return await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    ).then((userCredential) async {
      // Salvar usuário no Firestore
      await _usuariosRef.doc(userCredential.user?.uid).set({
        'nome': usuario.nome,
        'email': usuario.email,
        'tipo': usuario.tipo,
        'cpf': usuario.cpf,
        'uid': userCredential.user?.uid,
      });
      return 'Usuário cadastrado com sucesso';
    }).catchError((error) {
      return 'Erro ao cadastrar usuário: ${error.toString()}';
    });
  }

  Future<void> atualizarUsuario(String id, Usuario usuario) async {
    await _usuariosRef.doc(id).update({
      'nome': usuario.nome,
      'email': usuario.email,
      'tipo': usuario.tipo,
    });
  }
}