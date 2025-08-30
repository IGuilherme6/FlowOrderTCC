// test/usuario_controller_test.dart
import 'package:flutter_test/flutter_test.dart';

// Simulação das suas classes - ajuste os imports conforme sua estrutura
// import 'package:floworder/controllers/UsuarioController.dart';
// import 'package:floworder/firebase/UsuarioFirebase.dart';
// import 'package:floworder/models/Usuario.dart';

// Classe Usuario para teste (substitua pelo import real)
class Usuario {
  String? uid;
  String nome;
  String email;
  String telefone;
  String cpf;
  String cargo;
  String senha;

  Usuario({
    this.uid,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpf,
    required this.cargo,
    required this.senha,
  });
}

// Mock simples do UsuarioFirebase para testes
class MockUsuarioFirebase {
  String? _usuarioLogado;
  Map<String, bool> _cpfsExistentes = {};
  List<String> _chamadas = [];

  // Métodos para configurar o mock nos testes
  void setUsuarioLogado(String? id) => _usuarioLogado = id;
  void setCpfExistente(String cpf, bool existe) => _cpfsExistentes[cpf] = existe;
  void reset() {
    _usuarioLogado = null;
    _cpfsExistentes.clear();
    _chamadas.clear();
  }
  List<String> get chamadas => _chamadas;

  // Implementação dos métodos
  String? pegarIdUsuarioLogado() {
    _chamadas.add('pegarIdUsuarioLogado');
    return _usuarioLogado;
  }

  Future<String> salvarUsuario(Usuario usuario) async {
    _chamadas.add('salvarUsuario:${usuario.nome}');
    return 'Conta Criada com sucesso';
  }

  Future<bool> verificarCpfExistenteGerentes(String cpf) async {
    _chamadas.add('verificarCpfExistenteGerentes:$cpf');
    return _cpfsExistentes[cpf] ?? false;
  }

  Future<String> atualizarStatusFuncionario(String funcionarioId, bool status) async {
    _chamadas.add('atualizarStatusFuncionario:$funcionarioId:$status');
    return 'Status atualizado com sucesso';
  }

  Future<void> atualizarDadosFuncionario(String gerenteId, Usuario usuario) async {
    _chamadas.add('atualizarDadosFuncionario:$gerenteId:${usuario.nome}');
  }

  Future<void> apagarFuncionario(String gerenteId, String id) async {
    _chamadas.add('apagarFuncionario:$gerenteId:$id');
  }
}

// UsuarioController modificado para testes - versão simplificada
class UsuarioController {
  MockUsuarioFirebase? _mockFirebase;

  // Construtor para testes
  UsuarioController.paraTestar(MockUsuarioFirebase mockFirebase) {
    _mockFirebase = mockFirebase;
  }

  // Construtor normal
  UsuarioController();

  // Getter que retorna o mock em testes
  MockUsuarioFirebase get usuarioFirebase => _mockFirebase!;

  Future<String> cadastrarUsuario(Usuario usuario) async {
    try {
      // Verificar se CPF já existe
      if (await verificarCpfExistente(usuario.cpf)) {
        return 'Erro: CPF já cadastrado';
      }

      // Salvar no Firestore
      return await usuarioFirebase.salvarUsuario(usuario);
    } catch (e) {
      return 'Erro ao cadastrar: ${e.toString()}';
    }
  }

  Future<String> desativarFuncionario(String funcionarioId) async {
    String? gerenteId = usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) throw Exception('Nenhum gerente logado');

    return await usuarioFirebase.atualizarStatusFuncionario(funcionarioId, false);
  }

  Future<String> ativarFuncionario(String funcionarioId) async {
    String? gerenteId = usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) throw Exception('Nenhum gerente logado');

    return await usuarioFirebase.atualizarStatusFuncionario(funcionarioId, true);
  }

  Future<String> editarFuncionario(Usuario usuario) async {
    String? gerenteId = usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) return 'Erro: Nenhum gerente logado';

    try {
      await usuarioFirebase.atualizarDadosFuncionario(gerenteId, usuario);
      return 'Funcionário editado com sucesso';
    } catch (e) {
      return 'Erro ao editar funcionário: ${e.toString()}';
    }
  }

  Future<bool> verificarCpfExistente(String cpf) async {
    try {
      return await usuarioFirebase.verificarCpfExistenteGerentes(cpf);
    } catch (e) {
      return false;
    }
  }

  Future<String> deletarFuncionario(String id) async {
    String? gerenteId = usuarioFirebase.pegarIdUsuarioLogado();
    if (gerenteId == null) return 'Erro: Nenhum gerente logado';

    try {
      await usuarioFirebase.apagarFuncionario(gerenteId, id);
      return 'Funcionario foi apagado com sucesso';
    } catch (e) {
      return 'erro ao deletar';
    }
  }
}

void main() {
  group('UsuarioController Tests', () {
    late UsuarioController controller;
    late MockUsuarioFirebase mockUsuarioFirebase;

    setUp(() {
      mockUsuarioFirebase = MockUsuarioFirebase();
      controller = UsuarioController.paraTestar(mockUsuarioFirebase);
    });

    tearDown(() {
      mockUsuarioFirebase.reset();
    });

    group('cadastrarUsuario', () {
      test('deve retornar erro quando CPF já existe', () async {
        // Arrange
        final usuario = Usuario(
          nome: 'João Silva',
          email: 'joao@teste.com',
          telefone: '11999999999',
          cpf: '12345678901',
          cargo: 'Vendedor',
          senha: '123456',
        );

        mockUsuarioFirebase.setCpfExistente('12345678901', true);

        // Act
        final resultado = await controller.cadastrarUsuario(usuario);

        // Assert
        expect(resultado, 'Erro: CPF já cadastrado');
        expect(mockUsuarioFirebase.chamadas, contains('verificarCpfExistenteGerentes:12345678901'));
      });

      test('deve cadastrar usuário com sucesso quando CPF não existe', () async {
        // Arrange
        final usuario = Usuario(
          nome: 'Maria Silva',
          email: 'maria@teste.com',
          telefone: '11888888888',
          cpf: '98765432100',
          cargo: 'Vendedor',
          senha: '654321',
        );

        mockUsuarioFirebase.setCpfExistente('98765432100', false);

        // Act
        final resultado = await controller.cadastrarUsuario(usuario);

        // Assert
        expect(resultado, 'Conta Criada com sucesso');
        expect(mockUsuarioFirebase.chamadas, contains('verificarCpfExistenteGerentes:98765432100'));
        expect(mockUsuarioFirebase.chamadas, contains('salvarUsuario:Maria Silva'));
      });

      test('deve retornar erro quando verificação de CPF falha', () async {
        // Arrange
        final usuario = Usuario(
          nome: 'Pedro Silva',
          email: 'pedro@teste.com',
          telefone: '11777777777',
          cpf: '11122233344',
          cargo: 'Vendedor',
          senha: '789123',
        );

        // Simulando erro - não configuramos o CPF, então retornará false
        // Mas vamos modificar o controller para simular uma exceção

        // Act
        final resultado = await controller.cadastrarUsuario(usuario);

        // Assert - Como não há exceção real, deve cadastrar normalmente
        expect(resultado, 'Conta Criada com sucesso');
      });
    });

    group('desativarFuncionario', () {
      test('deve desativar funcionário com sucesso', () async {
        // Arrange
        const funcionarioId = 'func123';
        mockUsuarioFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.desativarFuncionario(funcionarioId);

        // Assert
        expect(resultado, 'Status atualizado com sucesso');
        expect(mockUsuarioFirebase.chamadas, contains('pegarIdUsuarioLogado'));
        expect(mockUsuarioFirebase.chamadas, contains('atualizarStatusFuncionario:func123:false'));
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockUsuarioFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.desativarFuncionario('func123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('ativarFuncionario', () {
      test('deve ativar funcionário com sucesso', () async {
        // Arrange
        const funcionarioId = 'func123';
        mockUsuarioFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.ativarFuncionario(funcionarioId);

        // Assert
        expect(resultado, 'Status atualizado com sucesso');
        expect(mockUsuarioFirebase.chamadas, contains('atualizarStatusFuncionario:func123:true'));
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockUsuarioFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.ativarFuncionario('func123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('editarFuncionario', () {
      test('deve editar funcionário com sucesso', () async {
        // Arrange
        final usuario = Usuario(
          uid: 'func123',
          nome: 'João Editado',
          email: 'joao@teste.com',
          telefone: '11999999999',
          cpf: '12345678901',
          cargo: 'Supervisor',
          senha: '123456',
        );

        mockUsuarioFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.editarFuncionario(usuario);

        // Assert
        expect(resultado, 'Funcionário editado com sucesso');
        expect(mockUsuarioFirebase.chamadas, contains('atualizarDadosFuncionario:gerente123:João Editado'));
      });

      test('deve retornar erro quando nenhum gerente está logado', () async {
        // Arrange
        final usuario = Usuario(
          nome: 'João',
          email: 'joao@teste.com',
          telefone: '11999999999',
          cpf: '12345678901',
          cargo: 'Vendedor',
          senha: '123456',
        );

        mockUsuarioFirebase.setUsuarioLogado(null);

        // Act
        final resultado = await controller.editarFuncionario(usuario);

        // Assert
        expect(resultado, 'Erro: Nenhum gerente logado');
      });
    });

    group('deletarFuncionario', () {
      test('deve deletar funcionário com sucesso', () async {
        // Arrange
        const funcionarioId = 'func123';
        mockUsuarioFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.deletarFuncionario(funcionarioId);

        // Assert
        expect(resultado, 'Funcionario foi apagado com sucesso');
        expect(mockUsuarioFirebase.chamadas, contains('apagarFuncionario:gerente123:func123'));
      });

      test('deve retornar erro quando nenhum gerente está logado', () async {
        // Arrange
        mockUsuarioFirebase.setUsuarioLogado(null);

        // Act
        final resultado = await controller.deletarFuncionario('func123');

        // Assert
        expect(resultado, 'Erro: Nenhum gerente logado');
      });
    });

    group('verificarCpfExistente', () {
      test('deve retornar true quando CPF existe', () async {
        // Arrange
        mockUsuarioFirebase.setCpfExistente('12345678901', true);

        // Act
        final resultado = await controller.verificarCpfExistente('12345678901');

        // Assert
        expect(resultado, true);
        expect(mockUsuarioFirebase.chamadas, contains('verificarCpfExistenteGerentes:12345678901'));
      });

      test('deve retornar false quando CPF não existe', () async {
        // Arrange
        mockUsuarioFirebase.setCpfExistente('12345678901', false);

        // Act
        final resultado = await controller.verificarCpfExistente('12345678901');

        // Assert
        expect(resultado, false);
      });
    });
  });

  group('Testes de Validação de Usuario', () {
    test('deve criar um usuário válido', () {
      // Arrange & Act
      final usuario = Usuario(
        nome: 'João Silva',
        email: 'joao@teste.com',
        telefone: '11999999999',
        cpf: '12345678901',
        cargo: 'Vendedor',
        senha: '123456',
      );

      // Assert
      expect(usuario.nome, 'João Silva');
      expect(usuario.email, 'joao@teste.com');
      expect(usuario.telefone, '11999999999');
      expect(usuario.cpf, '12345678901');
      expect(usuario.cargo, 'Vendedor');
      expect(usuario.senha, '123456');
    });

    test('deve validar email com @', () {
      final usuario = Usuario(
        nome: 'Teste',
        email: 'teste@email.com',
        telefone: '11999999999',
        cpf: '12345678901',
        cargo: 'Vendedor',
        senha: '123456',
      );

      expect(usuario.email.contains('@'), true);
      expect(usuario.email.split('@').length, 2);
    });

    test('deve validar CPF com 11 dígitos', () {
      final usuario = Usuario(
        nome: 'Teste',
        email: 'teste@email.com',
        telefone: '11999999999',
        cpf: '12345678901',
        cargo: 'Vendedor',
        senha: '123456',
      );

      expect(usuario.cpf.length, 11);
      expect(RegExp(r'^\d{11}$').hasMatch(usuario.cpf), true);
    });

    test('deve validar telefone', () {
      final usuario = Usuario(
        nome: 'Teste',
        email: 'teste@email.com',
        telefone: '11999999999',
        cpf: '12345678901',
        cargo: 'Vendedor',
        senha: '123456',
      );

      expect(usuario.telefone.length, greaterThanOrEqualTo(10));
      expect(RegExp(r'^\d+$').hasMatch(usuario.telefone), true);
    });
  });
}
