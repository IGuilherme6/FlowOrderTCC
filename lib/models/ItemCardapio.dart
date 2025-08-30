class ItemCardapio {
  String? uid;
  String nome;
  double preco;
  String categoria; // Ex: Bebida, Prato, Lanche

  ItemCardapio({
    this.uid,
    required this.nome,
    required this.preco,
    required this.categoria,
  });

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'nome': nome, 'preco': preco, 'categoria': categoria};
  }

  static ItemCardapio fromMap(Map<String, dynamic> map, String documentId) {
    return ItemCardapio(
      uid: documentId,
      nome: map['nome'],
      preco: map['preco'],
      categoria: map['categoria'],
    );
  }
}
