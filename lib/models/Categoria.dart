class Categoria {
  String uid;
  String nome;
  String gerenteUid; // Adicionado para associação

  Categoria({
    this.uid = '',
    required this.nome,
    required this.gerenteUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'gerenteUid': gerenteUid,
      // 'criadoEm': FieldValue.serverTimestamp(), // Se quiser adicionar timestamps
    };
  }

  factory Categoria.fromMap(String id, Map<String, dynamic> data) {
    return Categoria(
      uid: id,
      nome: data['nome'] ?? '',
      gerenteUid: data['gerenteUid'] ?? '',
    );
  }
}