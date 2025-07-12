import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Mesa.dart';

class MesaFirebase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pegar ID do usuário logado
  String? pegarIdUsuarioLogado() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Adicionar mesa no Firestore
  Future<String> adicionarMesa(String gerenteId, Mesa mesa) async {
    DocumentReference docRef = await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .add({
      'nome': mesa.nome,
      'numero': mesa.numero,
      'gerenteId': gerenteId,
      'criadoEm': FieldValue.serverTimestamp(),
    });

    // Atualizar o documento com seu próprio ID
    await docRef.update({'uid': docRef.id});

    return docRef.id;
  }

  /// Buscar mesas do gerente
  Future<QuerySnapshot> buscarMesas(String gerenteId) async {
    return await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .orderBy('numero')
        .get();
  }

  /// Stream para escutar mudanças nas mesas
  Stream<QuerySnapshot> streamMesas(String gerenteId) {
    return _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .orderBy('numero')
        .snapshots();
  }

  /// Deletar mesa
  Future<void> deletarMesa(String gerenteId, String mesaUid) async {
    await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .doc(mesaUid)
        .delete();
  }

  /// Atualizar mesa
  Future<void> atualizarMesa(String gerenteId, Mesa mesa) async {
    await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .doc(mesa.uid)
        .update({
      'nome': mesa.nome,
      'numero': mesa.numero,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Buscar mesa específica por UID
  Future<DocumentSnapshot> buscarMesaPorUid(String gerenteId, String mesaUid) async {
    return await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .doc(mesaUid)
        .get();
  }

  /// Converter DocumentSnapshot para Mesa
  Mesa documentParaMesa(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Mesa mesa = Mesa();
    mesa.uid = doc.id;
    mesa.nome = data['nome'];
    mesa.numero = data['numero'];
    return mesa;
  }

  /// Converter QuerySnapshot para List<Mesa>
  List<Mesa> querySnapshotParaMesas(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => documentParaMesa(doc)).toList();
  }

  Future<bool> verificarMesaExistente(String gerenteId, int numero) async {
    QuerySnapshot snapshot = await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .where('numero', isEqualTo: numero)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return true; // Mesa já existe
    }
    return false; // Mesa não existe
  }
}