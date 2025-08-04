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

  /// Adicionar mesa
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

    await docRef.update({'uid': docRef.id});
    return docRef.id;
  }

  /// Buscar mesas (snapshot único)
  Future<QuerySnapshot> buscarMesas(String gerenteId) async {
    return await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .orderBy('numero')
        .get();
  }

  /// Stream de mesas (tempo real)
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

  /// Buscar mesa específica
  Future<DocumentSnapshot> buscarMesaPorUid(String gerenteId, String mesaUid) async {
    return await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .doc(mesaUid)
        .get();
  }

  /// Converter DocumentSnapshot em Mesa
  Mesa documentParaMesa(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Mesa(
      uid: doc.id,
      nome: data['nome'] ?? "Mesa ${data['numero']}",
      numero: data['numero'] ?? 0,
    );
  }

  /// Converter QuerySnapshot em lista de mesas
  List<Mesa> querySnapshotParaMesas(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) => documentParaMesa(doc)).toList();
  }

  /// Verificar se já existe mesa com mesmo número
  Future<bool> verificarMesaExistente(String gerenteId, int numero) async {
    QuerySnapshot snapshot = await _firestore
        .collection('Gerentes')
        .doc(gerenteId)
        .collection('Mesas')
        .where('numero', isEqualTo: numero)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
