class Usuario {
  late String _nome;
  late String _email;
  late String _senha;
  List<String> _tipo = ['Garçom', 'Atendente', 'Cozinheiro'];

  String get nome => _nome;
  set nome(String value) => _nome = value;

  String get email => _email;
  set email(String value) => _email = value;

  List<String> get tipo => _tipo;
  set tipo(List<String> value) => _tipo = value;

  String get senha => _senha;
  set senha(String value) => _senha = value;

  void autenticar() {
    // lógica de autenticação
  }

  void alterarSenha() {
    // lógica de alteração de senha
  }
}
