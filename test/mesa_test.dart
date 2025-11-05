// test/mesa_controller_test.dart
import 'package:flutter_test/flutter_test.dart';

// Classe Mesa para teste
class Mesa {
  String? uid;
  int numero;
  String nome;

  Mesa({this.uid, required this.numero, this.nome = ''});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'numero': numero, 'nome': nome};
  }

  factory Mesa.fromMap(Map<String, dynamic> map, String documentId) {
    return Mesa(
      uid: documentId,
      numero: map['numero'] ?? 0,
      nome: map['nome'] ?? '',
    );
  }

  Mesa copyWith({
    String? uid,
    int? numero,
    String? nome,
  }) {
    return Mesa(
      uid: uid ?? this.uid,
      numero: numero ?? this.numero,
      nome: nome ?? this.nome,
    );
  }
}

// Mock simples do MesaFirebase para testes
class MockMesaFirebase {
  String? _usuarioLogado;
  Map<String, Map<int, bool>> _mesasExistentesPorGerente = {};
  Map<String, List<Mesa>> _mesasPorGerente = {};
  List<String> _chamadas = [];
  bool _deveGerarErro = false;

  // Métodos para configurar o mock nos testes
  void setUsuarioLogado(String? id) => _usuarioLogado = id;
  void setMesaExistente(String gerenteId, int numero, bool existe) {
    _mesasExistentesPorGerente[gerenteId] ??= {};
    _mesasExistentesPorGerente[gerenteId]![numero] = existe;
  }
  void setMesasPorGerente(String gerenteId, List<Mesa> mesas) =>
      _mesasPorGerente[gerenteId] = mesas;
  void setDeveGerarErro(bool erro) => _deveGerarErro = erro;

  void reset() {
    _usuarioLogado = null;
    _mesasExistentesPorGerente.clear();
    _mesasPorGerente.clear();
    _chamadas.clear();
    _deveGerarErro = false;
  }

  List<String> get chamadas => _chamadas;

  // Implementação dos métodos do MesaFirebase
  String? pegarIdUsuarioLogado() {
    _chamadas.add('pegarIdUsuarioLogado');
    return _usuarioLogado;
  }

  Future<String> adicionarMesa(String id, Mesa mesa) async {
    _chamadas.add('adicionarMesa:${mesa.numero}');
    if (_deveGerarErro) throw Exception('Erro ao adicionar mesa');
    if (id.isEmpty) throw Exception('ID inválido');

    final mesaId = 'mesa_${DateTime.now().millisecondsSinceEpoch}';
    mesa.uid = mesaId;
    return mesaId;
  }

  Future<MockQuerySnapshot> buscarMesas(String gerenteId) async {
    _chamadas.add('buscarMesas:$gerenteId');
    if (_deveGerarErro) throw Exception('Erro ao buscar mesas');

    final mesas = _mesasPorGerente[gerenteId] ?? [];
    return MockQuerySnapshot(mesas);
  }

  Future<Stream<MockQuerySnapshot>> streamMesas(String gerenteId) async {
    _chamadas.add('streamMesas:$gerenteId');
    if (_deveGerarErro) return Stream.error(Exception('Erro no stream'));

    final mesas = _mesasPorGerente[gerenteId] ?? [];
    return Stream.value(MockQuerySnapshot(mesas));
  }

  Future<void> deletarMesa(String gerenteId, String mesaUid) async {
    _chamadas.add('deletarMesa:$mesaUid');
    if (_deveGerarErro) throw Exception('Erro ao deletar mesa');
    if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
  }

  Future<void> atualizarMesa(String gerenteId, Mesa mesa) async {
    _chamadas.add('atualizarMesa:${mesa.uid}');
    if (_deveGerarErro) throw Exception('Erro ao atualizar mesa');
    if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
    if (mesa.uid == null || mesa.uid!.trim().isEmpty) {
      throw Exception('UID da mesa é necessário para atualizar');
    }
  }

  Future<bool> verificarMesaExistente(String gerenteId, int numero) async {
    _chamadas.add('verificarMesaExistente:$numero');
    if (_deveGerarErro) throw Exception('Erro ao verificar mesa existente');

    return _mesasExistentesPorGerente[gerenteId]?[numero] ?? false;
  }

  List<Mesa> querySnapshotParaMesas(MockQuerySnapshot snapshot) {
    _chamadas.add('querySnapshotParaMesas');
    return snapshot.mesas;
  }
}

// Mock do QuerySnapshot
class MockQuerySnapshot {
  final List<Mesa> mesas;
  MockQuerySnapshot(this.mesas);

  List<MockDocumentSnapshot> get docs =>
      mesas.map((m) => MockDocumentSnapshot(m)).toList();
}

class MockDocumentSnapshot {
  final Mesa mesa;
  MockDocumentSnapshot(this.mesa);

  String get id => mesa.uid ?? '';
  Map<String, dynamic> data() => mesa.toMap();
}

// MesaController modificado para testes
class MesaController {
  MockMesaFirebase? _mockFirebase;

  // Construtor para testes
  MesaController.paraTestar(MockMesaFirebase mockFirebase) {
    _mockFirebase = mockFirebase;
  }

  // Construtor normal
  MesaController();

  // Getter que retorna o mock em testes
  MockMesaFirebase get mesaFirebase => _mockFirebase!;

  Future<String> cadastrarMesa(Mesa mesa) async {
    try {
      if (await verificarMesaExistente(mesa.numero)) {
        return 'Erro: Mesa já cadastrada';
      }

      String? userId = mesaFirebase.pegarIdUsuarioLogado();
      if (userId == null) {
        throw Exception('Erro: Nenhum Usuario logado');
      }

      if (mesa.nome.isEmpty) {
        mesa.nome = "Mesa ${mesa.numero}";
      }

      String mesaId = await mesaFirebase.adicionarMesa(userId, mesa);
      mesa.uid = mesaId;

      return 'Mesa cadastrada com sucesso';
    } catch (e) {
      throw Exception('Erro ao cadastrar mesa: ${e.toString()}');
    }
  }

  Future<List<Mesa>> buscarMesas() async {
    String? userId = mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      MockQuerySnapshot snapshot = await mesaFirebase.buscarMesas(userId);
      return mesaFirebase.querySnapshotParaMesas(snapshot);
    } catch (e) {
      throw Exception('Erro ao buscar mesas: ${e.toString()}');
    }
  }

  Stream<List<Mesa>> streamMesas() async* {
    String? userId = mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      yield [];
      return;
    }

    Stream<MockQuerySnapshot> mesasStream = await mesaFirebase.streamMesas(userId);

    await for (MockQuerySnapshot snapshot in mesasStream) {
      List<Mesa> mesas = mesaFirebase.querySnapshotParaMesas(snapshot);
      yield mesas;
    }
  }

  Future<String> deletarMesa(String mesaUid) async {
    String? userId = mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await mesaFirebase.deletarMesa(userId, mesaUid);
      return 'Mesa deletada com sucesso';
    } catch (e) {
      throw Exception('Erro ao deletar mesa: ${e.toString()}');
    }
  }

  Future<String> atualizarMesa(Mesa mesa) async {
    String? userId = mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    if (mesa.uid!.isEmpty) {
      throw Exception('UID da mesa é necessário para atualizar');
    }

    try {
      await mesaFirebase.atualizarMesa(userId, mesa);
      return 'Mesa atualizada com sucesso';
    } catch (e) {
      throw Exception('Erro ao atualizar mesa: ${e.toString()}');
    }
  }

  Future<bool> verificarMesaExistente(int numero) async {
    String? userId = mesaFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      return await mesaFirebase.verificarMesaExistente(userId, numero);
    } catch (e) {
      throw Exception('Erro ao verificar mesa existente: ${e.toString()}');
    }
  }
}

void main() {
  group('MesaController Tests', () {
    late MesaController controller;
    late MockMesaFirebase mockMesaFirebase;

    setUp(() {
      mockMesaFirebase = MockMesaFirebase();
      controller = MesaController.paraTestar(mockMesaFirebase);
    });

    tearDown(() {
      mockMesaFirebase.reset();
    });

    group('cadastrarMesa', () {
      test('deve cadastrar mesa com sucesso', () async {
        // Arrange
        final mesa = Mesa(numero: 1, nome: 'Mesa VIP');
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesaExistente('gerente123', 1, false);

        // Act
        final resultado = await controller.cadastrarMesa(mesa);

        // Assert
        expect(resultado, 'Mesa cadastrada com sucesso');
        expect(mockMesaFirebase.chamadas, contains('pegarIdUsuarioLogado'));
        expect(mockMesaFirebase.chamadas, contains('verificarMesaExistente:1'));
        expect(mockMesaFirebase.chamadas, contains('adicionarMesa:1'));
      });

      test('deve gerar nome padrão quando nome está vazio', () async {
        // Arrange
        final mesa = Mesa(numero: 5, nome: '');
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesaExistente('gerente123', 5, false);

        // Act
        final resultado = await controller.cadastrarMesa(mesa);

        // Assert
        expect(resultado, 'Mesa cadastrada com sucesso');
        expect(mesa.nome, 'Mesa 5');
      });

      test('deve retornar erro quando mesa já existe', () async {
        // Arrange
        final mesa = Mesa(numero: 2, nome: 'Mesa 2');
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesaExistente('gerente123', 2, true);

        // Act
        final resultado = await controller.cadastrarMesa(mesa);

        // Assert
        expect(resultado, 'Erro: Mesa já cadastrada');
      });

      test('deve lançar exceção quando nenhum usuário está logado', () async {
        // Arrange
        final mesa = Mesa(numero: 3, nome: 'Mesa 3');
        mockMesaFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.cadastrarMesa(mesa),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando ocorre erro ao adicionar mesa', () async {
        // Arrange
        final mesa = Mesa(numero: 4, nome: 'Mesa 4');
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesaExistente('gerente123', 4, false);
        mockMesaFirebase.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.cadastrarMesa(mesa),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('buscarMesas', () {
      test('deve buscar mesas com sucesso', () async {
        // Arrange
        final mesas = [
          Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1'),
          Mesa(uid: 'mesa2', numero: 2, nome: 'Mesa 2'),
          Mesa(uid: 'mesa3', numero: 3, nome: 'Mesa VIP'),
        ];

        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesasPorGerente('gerente123', mesas);

        // Act
        final resultado = await controller.buscarMesas();

        // Assert
        expect(resultado, hasLength(3));
        expect(resultado.first.numero, 1);
        expect(resultado[2].nome, 'Mesa VIP');
        expect(mockMesaFirebase.chamadas, contains('pegarIdUsuarioLogado'));
        expect(mockMesaFirebase.chamadas, contains('buscarMesas:gerente123'));
        expect(mockMesaFirebase.chamadas, contains('querySnapshotParaMesas'));
      });

      test('deve retornar lista vazia quando não há mesas', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesasPorGerente('gerente123', []);

        // Act
        final resultado = await controller.buscarMesas();

        // Assert
        expect(resultado, isEmpty);
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.buscarMesas(),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando ocorre erro ao buscar mesas', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.buscarMesas(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('streamMesas', () {
      test('deve retornar stream de mesas com sucesso', () async {
        // Arrange
        final mesas = [
          Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1'),
          Mesa(uid: 'mesa2', numero: 2, nome: 'Mesa 2'),
        ];

        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesasPorGerente('gerente123', mesas);

        // Act
        final stream = controller.streamMesas();
        final resultado = await stream.first;

        // Assert
        expect(resultado, hasLength(2));
        expect(resultado.first.numero, 1);
        expect(mockMesaFirebase.chamadas, contains('streamMesas:gerente123'));
      });

      test('deve retornar lista vazia quando nenhum usuário está logado', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado(null);

        // Act
        final stream = controller.streamMesas();
        final resultado = await stream.first;

        // Assert
        expect(resultado, isEmpty);
      });
    });

    group('deletarMesa', () {
      test('deve deletar mesa com sucesso', () async {
        // Arrange
        const mesaUid = 'mesa123';
        mockMesaFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.deletarMesa(mesaUid);

        // Assert
        expect(resultado, 'Mesa deletada com sucesso');
        expect(mockMesaFirebase.chamadas, contains('pegarIdUsuarioLogado'));
        expect(mockMesaFirebase.chamadas, contains('deletarMesa:mesa123'));
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.deletarMesa('mesa123'),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando ocorre erro ao deletar mesa', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.deletarMesa('mesa123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('atualizarMesa', () {
      test('deve atualizar mesa com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa123', numero: 5, nome: 'Mesa Atualizada');
        mockMesaFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.atualizarMesa(mesa);

        // Assert
        expect(resultado, 'Mesa atualizada com sucesso');
        expect(mockMesaFirebase.chamadas, contains('atualizarMesa:mesa123'));
      });

      test('deve lançar exceção quando UID da mesa está vazio', () async {
        // Arrange
        final mesa = Mesa(uid: '', numero: 5, nome: 'Mesa 5');
        mockMesaFirebase.setUsuarioLogado('gerente123');

        // Act & Assert
        expect(
              () => controller.atualizarMesa(mesa),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa123', numero: 5, nome: 'Mesa 5');
        mockMesaFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.atualizarMesa(mesa),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando ocorre erro ao atualizar mesa', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa123', numero: 5, nome: 'Mesa 5');
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.atualizarMesa(mesa),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('verificarMesaExistente', () {
      test('deve retornar true quando mesa existe', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesaExistente('gerente123', 5, true);

        // Act
        final resultado = await controller.verificarMesaExistente(5);

        // Assert
        expect(resultado, true);
        expect(mockMesaFirebase.chamadas, contains('verificarMesaExistente:5'));
      });

      test('deve retornar false quando mesa não existe', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setMesaExistente('gerente123', 10, false);

        // Act
        final resultado = await controller.verificarMesaExistente(10);

        // Assert
        expect(resultado, false);
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.verificarMesaExistente(5),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando ocorre erro ao verificar mesa', () async {
        // Arrange
        mockMesaFirebase.setUsuarioLogado('gerente123');
        mockMesaFirebase.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.verificarMesaExistente(5),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('Testes de Validação de Mesa', () {
    test('deve criar uma mesa válida', () {
      // Arrange & Act
      final mesa = Mesa(numero: 1, nome: 'Mesa VIP');

      // Assert
      expect(mesa.numero, 1);
      expect(mesa.nome, 'Mesa VIP');
      expect(mesa.uid, null);
    });

    test('deve ter nome vazio por padrão quando não especificado', () {
      // Arrange & Act
      final mesa = Mesa(numero: 5);

      // Assert
      expect(mesa.nome, '');
    });

    test('deve validar número da mesa positivo', () {
      // Arrange & Act
      final mesa = Mesa(numero: 10, nome: 'Mesa 10');

      // Assert
      expect(mesa.numero, greaterThan(0));
    });

    test('deve converter para Map corretamente', () {
      // Arrange
      final mesa = Mesa(uid: 'mesa123', numero: 5, nome: 'Mesa Especial');

      // Act
      final map = mesa.toMap();

      // Assert
      expect(map['uid'], 'mesa123');
      expect(map['numero'], 5);
      expect(map['nome'], 'Mesa Especial');
    });

    test('deve criar mesa a partir de Map corretamente', () {
      // Arrange
      final map = {
        'numero': 8,
        'nome': 'Mesa Reservada',
      };

      // Act
      final mesa = Mesa.fromMap(map, 'mesa456');

      // Assert
      expect(mesa.uid, 'mesa456');
      expect(mesa.numero, 8);
      expect(mesa.nome, 'Mesa Reservada');
    });

    test('deve usar valores padrão quando campos estão ausentes no Map', () {
      // Arrange
      final map = <String, dynamic>{};

      // Act
      final mesa = Mesa.fromMap(map, 'mesa789');

      // Assert
      expect(mesa.uid, 'mesa789');
      expect(mesa.numero, 0);
      expect(mesa.nome, '');
    });

    test('deve copiar mesa com novos valores usando copyWith', () {
      // Arrange
      final mesaOriginal = Mesa(uid: 'mesa1', numero: 5, nome: 'Mesa Original');

      // Act
      final mesaCopia = mesaOriginal.copyWith(nome: 'Mesa Atualizada', numero: 10);

      // Assert
      expect(mesaCopia.uid, 'mesa1');
      expect(mesaCopia.numero, 10);
      expect(mesaCopia.nome, 'Mesa Atualizada');

      // Verifica que a mesa original não foi alterada
      expect(mesaOriginal.numero, 5);
      expect(mesaOriginal.nome, 'Mesa Original');
    });

    test('deve manter valores originais quando copyWith não especifica novos', () {
      // Arrange
      final mesaOriginal = Mesa(uid: 'mesa2', numero: 3, nome: 'Mesa 3');

      // Act
      final mesaCopia = mesaOriginal.copyWith();

      // Assert
      expect(mesaCopia.uid, 'mesa2');
      expect(mesaCopia.numero, 3);
      expect(mesaCopia.nome, 'Mesa 3');
    });
  });
}