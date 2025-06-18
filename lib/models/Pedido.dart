import 'package:flutter/cupertino.dart';
import 'ItemCardapio.dart';
import 'Mesa.dart';

class Pedido {
  late DateTime _horario;
  List<ItemCardapio> itens = [];   // inicializado aqui
  static List<String> _status = ['Aberto', 'Em Preparo', 'Pronto'];
  late Mesa _mesa;
  String _statusAtual = 'Aberto';

  DateTime get horario => _horario;

  set horario(DateTime value) {
    _horario = value;
  }

  Mesa get mesa => _mesa;

  set mesa(Mesa value) {
    _mesa = value;
  }

  String get statusAtual => _statusAtual;

  set statusAtual(String value) {
    _statusAtual = value;
  }

  static List<String> get status => _status;

  static set status(List<String> value) {
    _status = value;
  }

  void adicionarItem(ItemCardapio item) {
    itens.add(item);
  }

  double calcularTotal() {
    double total = 0.0;
    for (var item in itens) {
      total += item.preco;
    }
    return total;
  }
}
