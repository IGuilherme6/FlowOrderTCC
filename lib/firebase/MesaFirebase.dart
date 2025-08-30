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
  Future<String> adicionarMesa(String Id, Mesa mesa) async {
    final doc = await  FirebaseFirestore.instance
        .collection('Usuarios').doc(Id).get();
    final userData = doc.data() as Map<String, dynamic>?;
    final cargo = userData?['cargo'] as String?;

    if (cargo == "Gerente") {
      DocumentReference docRef = await _firestore
          .collection('Mesas')
          .add({
        'nome': mesa.nome,
        'numero': mesa.numero,
        'gerenteUid': Id,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      await docRef.update({'uid': docRef.id});
      return docRef.id;
    } else {
      final gerenteUid = userData?['gerenteUid'] as String?;
      DocumentReference docRef = await _firestore
          .collection('Mesas')
          .add({
        'nome': mesa.nome,
        'numero': mesa.numero,
        'gerenteUid': gerenteUid,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      await docRef.update({'uid': docRef.id});
      return docRef.id;
    }

  }

  /// Buscar mesas (snapshot único)
  Future<QuerySnapshot> buscarMesas(String gerenteUid) async {
    final doc = await  FirebaseFirestore.instance
        .collection('Usuarios').doc(gerenteUid).get();
    final userData = doc.data() as Map<String, dynamic>?;
    final Uid = userData?['gerenteUid'] as String?;
    return await _firestore
        .collection('Mesas')
        .orderBy('numero')
        .where('gerenteUid', isEqualTo: Uid)
        .get();
  }

  /// Stream de mesas (tempo real)
  Future<Stream<QuerySnapshot<Object?>>> streamMesas(String gerenteUid) async {
    final doc = await FirebaseFirestore.instance
        .collection('Usuarios').doc(gerenteUid).get();
    final userData = doc.data() as Map<String, dynamic>?;
    final Uid = userData?['gerenteUid'] as String?;

    return _firestore
        .collection('Mesas')
        .orderBy('numero')
        .where('gerenteUid', isEqualTo: Uid)
        .snapshots();
  }

  /// Deletar mesa
  Future<void> deletarMesa(String gerenteId, String mesaUid) async {
    await _firestore
        .collection('Mesas')
        .doc(mesaUid)
        .delete();
  }

  /// Atualizar mesa
  Future<void> atualizarMesa(String gerenteId, Mesa mesa) async {
    await _firestore
        .collection('Mesas')
        .doc(mesa.uid)
        .update({
          'nome': mesa.nome,
          'numero': mesa.numero,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
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
        .collection('Mesas')
        .where('numero', isEqualTo: numero)
        .where('gerenteUid', isEqualTo: gerenteId)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
