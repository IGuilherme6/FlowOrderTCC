class ItemCardapio {
  String? uid;
  String nome;
  double preco;
  String categoria; // Ex: Bebida, Prato, Lanche
  String? observacao; // Campo adicionado
  int quantidade;     // Campo adicionado

  ItemCardapio({
    this.uid,
    required this.nome,
    required this.preco,
    required this.categoria,
    this.observacao,
    this.quantidade = 1, // Valor padrão
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'preco': preco,
      'categoria': categoria,
      'observacao': observacao,
      'quantidade': quantidade,
    };
  }

  static ItemCardapio fromMap(Map<String, dynamic> map, String documentId) {
    return ItemCardapio(
      uid: documentId,
      nome: map['nome'],
      preco: map['preco'],
      categoria: map['categoria'],
      observacao: map['observacao'],
      quantidade: map['quantidade'] ?? 1,
    );
  }
}