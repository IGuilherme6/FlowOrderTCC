class Usuario {
  late String _nome;
  late String _email;
  late String _senha;
  late String _cpf;
  late String _telefone;
  late String _uidGerente;
  late String _cargo;

  String get nome => _nome;
  set nome(String value) => _nome = value;


  String get telefone => _telefone;

  set telefone(String value) {
    _telefone = value;
  }

  String get email => _email;
  set email(String value) => _email = value;


  String get cargo => _cargo;

  set cargo(String value) {
    _cargo = value;
  }

  String get senha => _senha;
  set senha(String value) => _senha = value;

  String get cpf => _cpf;
  set cpf(String value) => _cpf = value;
  void autenticar() {
    // lógica de autenticação
  }

  void alterarSenha() {
    // lógica de alteração de senha
  }

  String get uidGerente => _uidGerente;

  set uidGerente(String value) {
    _uidGerente = value;
  }
}
