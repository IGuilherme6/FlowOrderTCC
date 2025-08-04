class Cardapio {
  late String _nome;
  late String _descricao;
  late double _preco;
  late String _uid;
  late bool _ativo;

  String get nome => _nome;
  set nome(String value) => _nome = value;

  String get descricao => _descricao;
  set descricao(String value) => _descricao = value;

  double get preco => _preco;
  set preco(double value) => _preco = value;

  String get uid => _uid;
  set uid(String value) => _uid = value;

  bool get ativo => _ativo;
  set ativo(bool value) => _ativo = value;
}
