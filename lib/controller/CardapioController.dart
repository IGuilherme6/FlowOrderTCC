import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Cardapio.dart';

class CardapioController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> cadastrarCardapio(Cardapio cardapio) async {
    try {
      String? uidGerente = FirebaseAuth.instance.currentUser?.uid;
      if (uidGerente == null) throw Exception("Usuário não autenticado");

      await _firestore
          .collection('gerentes')
          .doc(uidGerente)
          .collection('cardapio')
          .add(cardapio.toMap());
    } catch (e) {
      throw Exception("Erro ao cadastrar cardápio: $e");
    }
  }

  Future<List<Cardapio>> buscarCardapiosDoGerente() async {
    try {
      String? uidGerente = FirebaseAuth.instance.currentUser?.uid;
      if (uidGerente == null) throw Exception("Usuário não autenticado");

      final snapshot = await _firestore
          .collection('gerentes')
          .doc(uidGerente)
          .collection('cardapio')
          .get();

      return snapshot.docs
          .map((doc) => Cardapio.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Erro ao buscar cardápios: $e");
    }
  }

  Future<void> atualizarCardapio(Cardapio cardapio) async {
    try {
      String? uidGerente = FirebaseAuth.instance.currentUser?.uid;
      if (uidGerente == null) throw Exception("Usuário não autenticado");

      await _firestore
          .collection('gerentes')
          .doc(uidGerente)
          .collection('cardapio')
          .doc(cardapio.uid)
          .update(cardapio.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar cardápio: $e");
    }
  }

  Future<void> excluirCardapio(String cardapioId) async {
    try {
      String? uidGerente = FirebaseAuth.instance.currentUser?.uid;
      if (uidGerente == null) throw Exception("Usuário não autenticado");

      await _firestore
          .collection('gerentes')
          .doc(uidGerente)
          .collection('cardapio')
          .doc(cardapioId)
          .delete();
    } catch (e) {
      throw Exception("Erro ao excluir cardápio: $e");
    }
  }

  Future<void> suspenderCardapio(String cardapioId, bool suspender) async {
    try {
      String? uidGerente = FirebaseAuth.instance.currentUser?.uid;
      if (uidGerente == null) throw Exception("Usuário não autenticado");

      await _firestore
          .collection('gerentes')
          .doc(uidGerente)
          .collection('cardapio')
          .doc(cardapioId)
          .update({'ativo': suspender});
    } catch (e) {
      throw Exception("Erro ao suspender/reativar cardápio: $e");
    }
  }
}
