// lib/controllers/usuario_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Usuario.dart';

class UsuarioController {
  final CollectionReference _usuariosRef =
  FirebaseFirestore.instance.collection('usuarios');

  Future<void> cadastrarUsuario(Usuario usuario) async {
    await _usuariosRef.add({
      'nome': usuario.nome,
      'email': usuario.email,
      'tipo': usuario.tipo,
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