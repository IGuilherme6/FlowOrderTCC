import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Pedido.dart';

class PedidoFirebase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _pedidosRef => _firestore.collection('pedidos');

  /// Adiciona um pedido no Firestore
  Future<String> adicionarPedido(Pedido pedido) async {
    try {
      DocumentReference docRef = await _pedidosRef.add(pedido.toMap());
      await docRef.update({'uid': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar pedido: $e');
    }
  }

  /// Atualiza o status de um pedido
  Future<void> atualizarStatus(String pedidoId, String novoStatus) async {
    try {
      await _pedidosRef.doc(pedidoId).update({'status': novoStatus});
    } catch (e) {
      throw Exception('Erro ao atualizar status do pedido: $e');
    }
  }

  /// Exclui um pedido
  Future<void> excluirPedido(String pedidoId) async {
    try {
      await _pedidosRef.doc(pedidoId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir pedido: $e');
    }
  }

  /// Busca todos os pedidos de uma vez (sem tempo real)
  Future<List<Pedido>> buscarPedidos() async {
    try {
      QuerySnapshot snapshot = await _pedidosRef.get();
      return snapshot.docs
          .map(
            (doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar pedidos: $e');
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
