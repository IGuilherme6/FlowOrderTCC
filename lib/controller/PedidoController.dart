import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Pedido.dart';

class PedidoController {
  final FirebaseFirestore _firestore;
  late final CollectionReference _pedidosRef;

  PedidoController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _pedidosRef = _firestore.collection('pedidos');
  }

  Future<void> cadastrarPedido(Pedido pedido) async {
    await _pedidosRef.add({
      'horario': pedido.horario,
      'status': Pedido.status,  // Aqui status precisa ser static ou acessível assim
      'mesa': pedido.mesa.numero,
      'itens': pedido.itens.map((item) => item.nome).toList(),
    });
  }

  Future<void> atualizarStatusPedido(String id, String status) async {
    await _pedidosRef.doc(id).update({
      'status': status,
    });
  }
}
