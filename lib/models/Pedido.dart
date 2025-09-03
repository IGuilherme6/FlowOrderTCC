import 'package:cloud_firestore/cloud_firestore.dart';
import 'ItemCardapio.dart';
import 'Mesa.dart';

class Pedido {
  String? uid;
  DateTime horario;
  Mesa mesa;
  List<ItemCardapio> itens;
  String statusAtual;
  String? observacao;

  // Lista de status possíveis
  static const List<String> statusOpcoes = [
    'Aberto',
    'Em Preparo',
    'Pronto',
    'Entregue',
    'Cancelado'
  ];

  Pedido({
    this.uid,
    required this.horario,
    required this.mesa,
    required this.itens,
    required this.statusAtual,
    this.observacao,
  });

  // Calcula o total do pedido
  double calcularTotal() {
    return itens.fold<double>(0, (total, item) => total + item.preco);
  }

  // Converte o pedido para Map para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horario': Timestamp.fromDate(horario),
      'mesa': mesa.toMap(),
      'itens': itens.map((item) => item.toMap()).toList(),
      'statusAtual': statusAtual,
      'observacao': observacao,
    };
  }

  // Cria um Pedido a partir de um Map do Firebase
  factory Pedido.fromMap(Map<String, dynamic> map, String documentId) {
    return Pedido(
      uid: documentId,
      horario: (map['horario'] as Timestamp).toDate(),
      mesa: Mesa.fromMap(map['mesa'] as Map<String, dynamic>, map['mesa']['uid'] ?? ''),
      itens: (map['itens'] as List<dynamic>)
          .map((item) => ItemCardapio.fromMap(item as Map<String, dynamic>, item['uid'] ?? ''))
          .toList(),
      statusAtual: map['statusAtual'] ?? 'Aberto',
      observacao: map['observacao'],
    );
  }

  // Copia o pedido com novos valores
  Pedido copyWith({
    String? uid,
    DateTime? horario,
    Mesa? mesa,
    List<ItemCardapio>? itens,
    String? statusAtual,
    String? observacao,
  }) {
    return Pedido(
      uid: uid ?? this.uid,
      horario: horario ?? this.horario,
      mesa: mesa ?? this.mesa,
      itens: itens ?? this.itens,
      statusAtual: statusAtual ?? this.statusAtual,
      observacao: observacao ?? this.observacao,
    );
  }
}