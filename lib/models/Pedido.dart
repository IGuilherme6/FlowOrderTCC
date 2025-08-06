import 'ItemCardapio.dart';
import 'Mesa.dart';

class Pedido {
  String? uid;
  DateTime horario;
  List<ItemCardapio> itens;
  static List<String> statusOpcoes = ['Aberto', 'Em Preparo', 'Pronto'];
  Mesa mesa;
  String statusAtual;

  Pedido({
    this.uid,
    required this.horario,
    required this.mesa,
    required this.itens,
    this.statusAtual = 'Aberto',
  });

  double calcularTotal() {
    return itens.fold(0.0, (total, item) => total + item.preco);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horario': horario.toIso8601String(),
      'status': statusAtual,
      'mesa': {
        'uid': mesa.uid,
        'numero': mesa.numero,
        'nome': mesa.nome,
      },
      'itens': itens.map((item) => item.toMap()).toList(),
      'total': calcularTotal(),
    };
  }

  static Pedido fromMap(Map<String, dynamic> map, String documentId) {
    return Pedido(
      uid: documentId,
      horario: DateTime.parse(map['horario']),
      mesa: Mesa()
        ..uid = map['mesa']['uid']
        ..numero = map['mesa']['numero']
        ..nome = map['mesa']['nome'],
      itens: (map['itens'] as List<dynamic>)
          .map((item) => ItemCardapio.fromMap(item as Map<String, dynamic>, item['uid'] ?? ''))
          .toList(),
      statusAtual: map['status'] ?? 'Aberto',
    );
  }
}
