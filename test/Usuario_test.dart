import '../lib/models/Usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Usuario', () {
    late Usuario usuario;

    setUp(() {
      usuario = Usuario();
    });

    test('deve definir e obter nome corretamente', () {
      usuario.nome = 'João';
      expect(usuario.nome, equals('João'));
    });

    test('deve definir e obter email corretamente', () {
      usuario.email = 'joao@email.com';
      expect(usuario.email, equals('joao@email.com'));
    });

    test('deve definir e obter senha corretamente', () {
      usuario.senha = '123456';
      expect(usuario.senha, equals('123456'));
    });

    test('deve ter tipos de usuário válidos', () {
      expect(usuario.tipo, containsAll(['Garçom', 'Atendente', 'Cozinheiro']));
    });

    test('deve permitir definir tipos de usuário customizados', () {
      usuario.tipo = ['Gerente', 'Administrador'];
      expect(usuario.tipo, equals(['Gerente', 'Administrador']));
    });

    test('métodos autenticar e alterarSenha devem existir e não lançar', () {
      expect(() => usuario.autenticar(), returnsNormally);
      expect(() => usuario.alterarSenha(), returnsNormally);
    });
  });
}
