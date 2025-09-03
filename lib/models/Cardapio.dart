class Cardapio {
  String uid;
  String nome;
  String descricao;
  double preco;
  bool ativo;
  String categoria;

  Cardapio({
    this.uid = '',
    required this.nome,
    required this.descricao,
    required this.preco,
    this.ativo = true,
    this.categoria = 'Outros',
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'ativo': ativo,
      'categoria': categoria,
    };
  }

  factory Cardapio.fromMap(String id, Map<String, dynamic> data) {
    return Cardapio(
      uid: id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      ativo: data['ativo'] ?? true,
      categoria: data['categoria'] ?? 'Outros',
    );
  }

}
