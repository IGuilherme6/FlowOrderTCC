import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Pedido.dart';

class PedidoController {
  final FirebaseFirestore _firestore;
  late final CollectionReference _pedidosRef;

  PedidoController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _pedidosRef = _firestore.collection('pedidos');
  }

  /// Cadastra um novo pedido no Firestore
  Future<void> cadastrarPedido(Pedido pedido) async {
    try {
      DocumentReference docRef = await _pedidosRef.add(pedido.toMap());
      await docRef.update({'uid': docRef.id});
    } catch (e) {
      throw Exception('Erro ao cadastrar pedido: $e');
    }
  }

  /// Atualiza o status de um pedido pelo UID
  Future<void> atualizarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await _pedidosRef.doc(pedidoId).update({'status': novoStatus});
    } catch (e) {
      throw Exception('Erro ao atualizar status do pedido: $e');
    }
  }

  /// Ouve pedidos em tempo real
  Stream<List<Pedido>> ouvirPedidosTempoReal() {
    return _pedidosRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
