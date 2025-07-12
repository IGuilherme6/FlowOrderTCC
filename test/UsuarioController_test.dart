import 'package:floworder/controller/UsuarioController.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import 'package:floworder/models/Usuario.dart';

// Gerar mocks
@GenerateMocks([UsuarioFirebase, DocumentSnapshot, QuerySnapshot])
import 'UsuarioController_test.mocks.dart';
void main() {
  group('UsuarioController Tests', () {
    late UsuarioController usuarioController;
    late MockUsuarioFirebase mockUsuarioFirebase;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;

    setUp(() {
      mockUsuarioFirebase = MockUsuarioFirebase();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();

      // Injeção de dependência manual - pode ser necessário refatorar o controller
      usuarioController = UsuarioController();
      // Note: O controller precisa ser refatorado para aceitar dependências injetadas
    });

    group('cadastrarGerente', () {
      test('deve cadastrar gerente com sucesso', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'test_id';
        usuario.nome = 'João Silva';
        usuario.email = 'joao@email.com';
        usuario.cpf = '12345678901';
        usuario.senha = 'senha123';
        usuario.cargo = 'Gerente';
        usuario.telefone = '67999999999';

        when(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.verificarCpfExistenteFuncionarios(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.criarUsuarioAuth(usuario.email, usuario.senha))
            .thenAnswer((_) async => 'user_id_123');
        when(mockUsuarioFirebase.salvarGerente('user_id_123', usuario))
            .thenAnswer((_) async => {});

        // Act
        final resultado = await usuarioController.cadastrarGerente(usuario);

        // Assert
        expect(resultado, 'Gerente cadastrado com sucesso');
        verify(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf)).called(1);
        verify(mockUsuarioFirebase.verificarCpfExistenteFuncionarios(usuario.cpf)).called(1);
        verify(mockUsuarioFirebase.criarUsuarioAuth(usuario.email, usuario.senha)).called(1);
        verify(mockUsuarioFirebase.salvarGerente('user_id_123', usuario)).called(1);
      });

      test('deve retornar erro quando CPF já existe', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'test_id';
        usuario.nome = 'João Silva';
        usuario.email = 'joao@email.com';
        usuario.cpf = '12345678901';
        usuario.senha = 'senha123';
        usuario.cargo = 'Gerente';
        usuario.telefone = '67999999999';

        when(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf))
            .thenAnswer((_) async => true);

        // Act
        final resultado = await usuarioController.cadastrarGerente(usuario);

        // Assert
        expect(resultado, 'Erro: CPF já cadastrado');
        verify(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf)).called(1);
        verifyNever(mockUsuarioFirebase.criarUsuarioAuth(any, any));
      });

      test('deve retornar erro quando falha ao criar usuário', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'test_id';
        usuario.nome = 'João Silva';
        usuario.email = 'joao@email.com';
        usuario.cpf = '12345678901';
        usuario.senha = 'senha123';
        usuario.cargo = 'Gerente';
        usuario.telefone = '67999999999';

        when(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.verificarCpfExistenteFuncionarios(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.criarUsuarioAuth(usuario.email, usuario.senha))
            .thenThrow(Exception('Erro ao criar usuário'));

        // Act
        final resultado = await usuarioController.cadastrarGerente(usuario);

        // Assert
        expect(resultado, contains('Erro ao cadastrar'));
        expect(resultado, contains('Erro ao criar usuário'));
      });
    });

    group('cadastrarFuncionario', () {
      test('deve cadastrar funcionário com sucesso', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'test_id';
        usuario.nome = 'Maria Santos';
        usuario.email = 'maria@email.com';
        usuario.cpf = '98765432101';
        usuario.senha = 'senha456';
        usuario.cargo = 'Funcionário';
        usuario.telefone = '67888888888';

        when(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.verificarCpfExistenteFuncionarios(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.buscarGerente('gerente_id_123'))
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({'cargo': 'Gerente'});
        when(mockUsuarioFirebase.criarUsuarioAuthSecundario(usuario.email, usuario.senha))
            .thenAnswer((_) async => 'funcionario_id_456');
        when(mockUsuarioFirebase.salvarFuncionario('gerente_id_123', 'funcionario_id_456', usuario))
            .thenAnswer((_) async => {});

        // Act
        final resultado = await usuarioController.cadastrarFuncionario(usuario);

        // Assert
        expect(resultado, 'Funcionário cadastrado com sucesso');
        verify(mockUsuarioFirebase.pegarIdUsuarioLogado()).called(1);
        verify(mockUsuarioFirebase.buscarGerente('gerente_id_123')).called(1);
        verify(mockUsuarioFirebase.criarUsuarioAuthSecundario(usuario.email, usuario.senha)).called(1);
      });

      test('deve retornar erro quando nenhum gerente está logado', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'test_id';
        usuario.nome = 'Maria Santos';
        usuario.email = 'maria@email.com';
        usuario.cpf = '98765432101';
        usuario.senha = 'senha456';
        usuario.cargo = 'Funcionário';
        usuario.telefone = '67888888888';

        when(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.verificarCpfExistenteFuncionarios(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.pegarIdUsuarioLogado()).thenReturn(null);

        // Act
        final resultado = await usuarioController.cadastrarFuncionario(usuario);

        // Assert
        expect(resultado, 'Erro: Nenhum gerente logado');
        verifyNever(mockUsuarioFirebase.criarUsuarioAuthSecundario(any, any));
      });

      test('deve retornar erro quando usuário logado não é gerente', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'test_id';
        usuario.nome = 'Maria Santos';
        usuario.email = 'maria@email.com';
        usuario.cpf = '98765432101';
        usuario.senha = 'senha456';
        usuario.cargo = 'Funcionário';
        usuario.telefone = '67888888888';

        when(mockUsuarioFirebase.verificarCpfExistenteGerentes(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.verificarCpfExistenteFuncionarios(usuario.cpf))
            .thenAnswer((_) async => false);
        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('usuario_id_123');
        when(mockUsuarioFirebase.buscarGerente('usuario_id_123'))
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({'cargo': 'Funcionário'});

        // Act
        final resultado = await usuarioController.cadastrarFuncionario(usuario);

        // Assert
        expect(resultado, 'Erro: Apenas gerentes podem cadastrar funcionários');
        verifyNever(mockUsuarioFirebase.criarUsuarioAuthSecundario(any, any));
      });
    });

    group('listarFuncionariosAtivos', () {
      test('deve retornar stream de funcionários ativos', () {
        // Arrange
        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.listarFuncionariosAtivos('gerente_id_123'))
            .thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final stream = usuarioController.listarFuncionariosAtivos();

        // Assert
        expect(stream, isA<Stream<QuerySnapshot>>());
        verify(mockUsuarioFirebase.pegarIdUsuarioLogado()).called(1);
        verify(mockUsuarioFirebase.listarFuncionariosAtivos('gerente_id_123')).called(1);
      });

      test('deve lançar exceção quando nenhum gerente está logado', () {
        // Arrange
        when(mockUsuarioFirebase.pegarIdUsuarioLogado()).thenReturn(null);

        // Act & Assert
        expect(() => usuarioController.listarFuncionariosAtivos(),
            throwsA(isA<Exception>()));
      });
    });

    group('listarFuncionariosInativos', () {
      test('deve retornar stream de funcionários inativos', () {
        // Arrange
        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.listarFuncionariosInativos('gerente_id_123'))
            .thenAnswer((_) => Stream.value(mockQuerySnapshot));

        // Act
        final stream = usuarioController.listarFuncionariosInativos();

        // Assert
        expect(stream, isA<Stream<QuerySnapshot>>());
        verify(mockUsuarioFirebase.pegarIdUsuarioLogado()).called(1);
        verify(mockUsuarioFirebase.listarFuncionariosInativos('gerente_id_123')).called(1);
      });

      test('deve lançar exceção quando nenhum gerente está logado', () {
        // Arrange
        when(mockUsuarioFirebase.pegarIdUsuarioLogado()).thenReturn(null);

        // Act & Assert
        expect(() => usuarioController.listarFuncionariosInativos(),
            throwsA(isA<Exception>()));
      });
    });

    group('desativarFuncionario', () {
      test('deve desativar funcionário com sucesso', () async {
        // Arrange
        const funcionarioId = 'funcionario_id_456';
        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.atualizarStatusFuncionario(
            'gerente_id_123', funcionarioId, false))
            .thenAnswer((_) async => {});

        // Act
        await usuarioController.desativarFuncionario(funcionarioId);

        // Assert
        verify(mockUsuarioFirebase.pegarIdUsuarioLogado()).called(1);
        verify(mockUsuarioFirebase.atualizarStatusFuncionario(
            'gerente_id_123', funcionarioId, false)).called(1);
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        const funcionarioId = 'funcionario_id_456';
        when(mockUsuarioFirebase.pegarIdUsuarioLogado()).thenReturn(null);

        // Act & Assert
        expect(() async => await usuarioController.desativarFuncionario(funcionarioId),
            throwsA(isA<Exception>()));
      });
    });

    group('ativarFuncionario', () {
      test('deve ativar funcionário com sucesso', () async {
        // Arrange
        const funcionarioId = 'funcionario_id_456';
        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.atualizarStatusFuncionario(
            'gerente_id_123', funcionarioId, true))
            .thenAnswer((_) async => {});

        // Act
        await usuarioController.ativarFuncionario(funcionarioId);

        // Assert
        verify(mockUsuarioFirebase.pegarIdUsuarioLogado()).called(1);
        verify(mockUsuarioFirebase.atualizarStatusFuncionario(
            'gerente_id_123', funcionarioId, true)).called(1);
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        const funcionarioId = 'funcionario_id_456';
        when(mockUsuarioFirebase.pegarIdUsuarioLogado()).thenReturn(null);

        // Act & Assert
        expect(() async => await usuarioController.ativarFuncionario(funcionarioId),
            throwsA(isA<Exception>()));
      });
    });

    group('editarFuncionario', () {
      test('deve editar funcionário com sucesso', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'funcionario_id_456';
        usuario.nome = 'Maria Silva Editada';
        usuario.email = 'maria.editada@email.com';
        usuario.cpf = '98765432101';
        usuario.senha = 'novaSenha123';
        usuario.cargo = 'Funcionário';
        usuario.telefone = '67777777777';

        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.atualizarDadosFuncionario('gerente_id_123', usuario))
            .thenAnswer((_) async => {});

        // Act
        final resultado = await usuarioController.editarFuncionario(usuario);

        // Assert
        expect(resultado, 'Funcionário editado com sucesso');
        verify(mockUsuarioFirebase.pegarIdUsuarioLogado()).called(1);
        verify(mockUsuarioFirebase.atualizarDadosFuncionario('gerente_id_123', usuario)).called(1);
      });

      test('deve retornar erro quando nenhum gerente está logado', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'funcionario_id_456';
        usuario.nome = 'Maria Silva Editada';
        usuario.email = 'maria.editada@email.com';
        usuario.cpf = '98765432101';
        usuario.senha = 'novaSenha123';
        usuario.cargo = 'Funcionário';
        usuario.telefone = '67777777777';

        when(mockUsuarioFirebase.pegarIdUsuarioLogado()).thenReturn(null);

        // Act
        final resultado = await usuarioController.editarFuncionario(usuario);

        // Assert
        expect(resultado, 'Erro: Nenhum gerente logado');
        verifyNever(mockUsuarioFirebase.atualizarDadosFuncionario(any, any));
      });

      test('deve retornar erro quando falha ao atualizar dados', () async {
        // Arrange
        final usuario = Usuario();
        usuario.uid = 'funcionario_id_456';
        usuario.nome = 'Maria Silva Editada';
        usuario.email = 'maria.editada@email.com';
        usuario.cpf = '98765432101';
        usuario.senha = 'novaSenha123';
        usuario.cargo = 'Funcionário';
        usuario.telefone = '67777777777';

        when(mockUsuarioFirebase.pegarIdUsuarioLogado())
            .thenReturn('gerente_id_123');
        when(mockUsuarioFirebase.atualizarDadosFuncionario('gerente_id_123', usuario))
            .thenThrow(Exception('Erro ao atualizar dados'));

        // Act
        final resultado = await usuarioController.editarFuncionario(usuario);

        // Assert
        expect(resultado, contains('Erro ao editar funcionário'));
        expect(resultado, contains('Erro ao atualizar dados'));
      });
    });
  });
}

// Importar a classe Usuario real
// import 'package:floworder/models/Usuario.dart';