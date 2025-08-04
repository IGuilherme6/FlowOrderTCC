import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Cardapio.dart';

class CardapioFirebase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<String> adicionarCardapio(String gerenteId, Cardapio cardapio) async {
    DocumentReference docRef = await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Cardapios')
        .add({
      'nome': cardapio.nome,
      'descricao': cardapio.descricao,
      'preco': cardapio.preco,
      'categoria': cardapio.categoria, // Adicionando categoria
      'ativo': true,
      'gerenteId': gerenteId,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    await docRef.update({'uid': docRef.id});
    return docRef.id;
  }

  Future<QuerySnapshot> buscarCardapios(String gerenteId) async {
    return await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Cardapios')
        .orderBy('categoria') // Ordena por categoria primeiro
        .orderBy('nome') // Depois ordena por nome
        .get();
  }

  Future<void> atualizarCardapio(String gerenteId, Cardapio cardapio) async {
    await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Cardapios')
        .doc(cardapio.uid)
        .update({
      'nome': cardapio.nome,
      'descricao': cardapio.descricao,
      'preco': cardapio.preco,
      'categoria': cardapio.categoria, // Permite atualizar a categoria
    });
  }

  Future<void> excluirCardapio(String gerenteId, String cardapioId) async {
    await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Cardapios')
        .doc(cardapioId)
        .delete();
  }

  Future<void> suspenderCardapio(String gerenteId, String cardapioId, bool ativo) async {
    await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Cardapios')
        .doc(cardapioId)
        .update({'ativo': ativo});
  }
}
