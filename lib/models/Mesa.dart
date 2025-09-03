class Mesa {
  String? uid;
  int numero;
  String nome;

  Mesa({
    this.uid,
    required this.numero,
    this.nome = '',
  });

  // Converte a mesa para Map para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'numero': numero,
      'nome': nome,
    };
  }

  // Cria uma Mesa a partir de um Map do Firebase
  factory Mesa.fromMap(Map<String, dynamic> map, String documentId) {
    return Mesa(
      uid: documentId,
      numero: map['numero'] ?? 0,
      nome: map['nome'] ?? '',
    );
  }

  // Copia a mesa com novos valores
  Mesa copyWith({
    String? uid,
    int? numero,
    String? nome,
    int? capacidade,
    bool? ativa,
  }) {
    return Mesa(
      uid: uid ?? this.uid,
      numero: numero ?? this.numero,
      nome: nome ?? this.nome,
    );
  }
}