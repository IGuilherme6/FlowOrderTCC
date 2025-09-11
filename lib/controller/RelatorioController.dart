import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/models/Pedido.dart';

class RelatorioController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Relatório de todos os pedidos feitos
  Future<List<Pedido>> listarPedidos() async {
    var snapshot = await _db.collection('pedidos').get();
    return snapshot.docs.map((doc) => Pedido.fromFirestore(doc)).toList();
  }

  /// Relatório dos produtos/lanches mais vendidos
  Future<Map<String, int>> produtosMaisVendidos() async {
    var snapshot = await _db.collection('pedidos').get();
    Map<String, int> ranking = {};

    for (var doc in snapshot.docs) {
      Pedido pedido = Pedido.fromFirestore(doc);
      for (var produto in pedido.itens) {
        ranking[produto.nome] = (ranking[produto.nome] ?? 0) + produto.quantidade;
      }
    }

    return Map.fromEntries(
      ranking.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Relatório de quantidade de pedidos por dia
  Future<Map<String, int>> pedidosPorDia() async {
    var snapshot = await _db.collection('pedidos').get();
    Map<String, int> porDia = {};

    for (var doc in snapshot.docs) {
      Pedido pedido = Pedido.fromFirestore(doc);
      String data = "${pedido.data.day}/${pedido.data.month}/${pedido.data.year}";
      porDia[data] = (porDia[data] ?? 0) + 1;
    }

    return porDia;
  }

  /// Relatório filtrado por período
  Future<List<Pedido>> pedidosPorPeriodo(DateTime inicio, DateTime fim) async {
    var snapshot = await _db.collection('pedidos')
        .where('data', isGreaterThanOrEqualTo: inicio)
        .where('data', isLessThanOrEqualTo: fim)
        .get();

    return snapshot.docs.map((doc) => Pedido.fromFirestore(doc)).toList();
  }
}
