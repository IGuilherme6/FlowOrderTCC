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
        .collection('Cardapios').add({
      'nome': cardapio.nome,
      'descricao': cardapio.descricao,
      'preco': cardapio.preco,
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
        .orderBy('nome')
        .get();
  }

}