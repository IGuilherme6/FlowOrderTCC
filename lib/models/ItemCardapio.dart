import 'dart:ffi';

class ItemCardapio {
  late String _nome;
  late String _descricao;
  late double _preco;

  String get nome => _nome;

  set nome(String value) {
    _nome = value;
  }

  String get descricao => _descricao;

  double get preco => _preco;

  set preco(double value) {
    _preco = value;
  }

  set descricao(String value) {
    _descricao = value;
  }
}

