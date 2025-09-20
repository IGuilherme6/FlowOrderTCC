// test/cardapio_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simulação das suas classes - ajuste os imports conforme sua estrutura
// import 'package:floworder/controllers/CardapioController.dart';
// import 'package:floworder/firebase/CardapioFirebase.dart';
// import 'package:floworder/models/Cardapio.dart';
// import 'package:floworder/models/Categoria.dart';

// Classe Cardapio para teste (substitua pelo import real)
class Cardapio {
  String? uid;
  String nome;
  String descricao;
  double preco;
  bool ativo;
  String categoria;
  String? observacao;

  Cardapio({
    this.uid = '',
    required this.nome,
    required this.descricao,
    required this.preco,
    this.ativo = true,
    this.categoria = 'Outros',
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'ativo': ativo,
      'categoria': categoria,
    };
  }

  factory Cardapio.fromMap(String id, Map<String, dynamic> data) {
    return Cardapio(
      uid: id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      ativo: data['ativo'] ?? true,
      categoria: data['categoria'] ?? 'Outros',
    );
  }
}

// Classe Categoria para teste (substitua pelo import real)
class Categoria {
  String? uid;
  String nome;

  Categoria({
    this.uid,
    required this.nome,
  });

  factory Categoria.fromMap(String id, Map<String, dynamic> data) {
    return Categoria(
      uid: id,
      nome: data['nome'] ?? '',
    );
  }
}

// Mock simples do CardapioFirebase para testes
class MockCardapioFirebase {
  String? _usuarioLogado;
  String? _gerenteUid;
  Map<String, bool> _cardapiosExistentes = {};
  Map<String, List<Cardapio>> _cardapiosPorGerente = {};
  Map<String, List<Categoria>> _categoriasPorGerente = {};
  List<String> _chamadas = [];
  bool _deveGerarErro = false;

  // Métodos para configurar o mock nos testes
  void setUsuarioLogado(String? id) => _usuarioLogado = id;
  void setGerenteUid(String? id) => _gerenteUid = id;
  void setCardapioExistente(String id, bool existe) => _cardapiosExistentes[id] = existe;
  void setCardapiosPorGerente(String gerenteId, List<Cardapio> cardapios) => _cardapiosPorGerente[gerenteId] = cardapios;
  void setCategoriasPorGerente(String gerenteId, List<Categoria> categorias) => _categoriasPorGerente[gerenteId] = categorias;
  void setDeveGerarErro(bool erro) => _deveGerarErro = erro;

  void reset() {
    _usuarioLogado = null;
    _gerenteUid = null;
    _cardapiosExistentes.clear();
    _cardapiosPorGerente.clear();
    _categoriasPorGerente.clear();
    _chamadas.clear();
    _deveGerarErro = false;
  }

  List<String> get chamadas => _chamadas;

  // Implementação dos métodos do CardapioFirebase
  String? pegarIdUsuarioLogado() {
    _chamadas.add('pegarIdUsuarioLogado');
    return _usuarioLogado;
  }

  Future<String?> verificarGerenteUid() async {
    _chamadas.add('verificarGerenteUid');
    if (_deveGerarErro) throw Exception('Erro simulado');
    return _gerenteUid;
  }

  Future<String> adicionarCardapio(String id, Cardapio cardapio) async {
    _chamadas.add('adicionarCardapio:${cardapio.nome}');
    if (_deveGerarErro) throw Exception('Erro ao adicionar cardápio');
    if (id.isEmpty) throw Exception('inválido');

    final cardapioId = 'cardapio_${DateTime.now().millisecondsSinceEpoch}';
    cardapio.uid = cardapioId;
    return cardapioId;
  }

  Future<List<Cardapio>> buscarCardapios(String gerenteId) async {
    _chamadas.add('buscarCardapios:$gerenteId');
    if (_deveGerarErro) throw Exception('Erro ao buscar cardápios');
    return _cardapiosPorGerente[gerenteId] ?? [];
  }

  Stream<List<Cardapio>> streamCardapios(String gerenteId) {
    _chamadas.add('streamCardapios:$gerenteId');
    if (_deveGerarErro) return Stream.error(Exception('Erro no stream'));
    return Stream.value(_cardapiosPorGerente[gerenteId] ?? []);
  }

  Future<void> atualizarCardapio(String gerenteId, Cardapio cardapio) async {
    _chamadas.add('atualizarCardapio:${cardapio.uid}');
    if (_deveGerarErro) throw Exception('Erro ao atualizar cardápio');
    if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
    if (cardapio.uid == null || cardapio.uid!.trim().isEmpty) {
      throw Exception('UID do cardápio é necessário para atualizar');
    }
  }

  Future<void> excluirCardapio(String gerenteId, String cardapioId) async {
    _chamadas.add('excluirCardapio:$cardapioId');
    if (_deveGerarErro) throw Exception('Erro ao excluir cardápio');
    if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
  }

  Future<void> suspenderCardapio(String gerenteId, String cardapioId, bool ativo) async {
    _chamadas.add('suspenderCardapio:$cardapioId:$ativo');
    if (_deveGerarErro) throw Exception('Erro ao suspender cardápio');
    if (gerenteId.isEmpty) throw Exception('GerenteId inválido');
  }

  Future<String> adicionarCategoria(String gerenteId, String nome) async {
    _chamadas.add('adicionarCategoria:$nome');
    if (_deveGerarErro) throw Exception('Erro ao adicionar categoria');
    if (nome.trim().isEmpty) throw Exception('O nome da categoria não pode estar vazio.');

    final categoriaId = 'categoria_${DateTime.now().millisecondsSinceEpoch}';
    return categoriaId;
  }

  Stream<List<Categoria>> streamCategorias(String gerenteId) {
    _chamadas.add('streamCategorias:$gerenteId');
    if (_deveGerarErro) return Stream.error(Exception('Erro no stream de categorias'));
    return Stream.value(_categoriasPorGerente[gerenteId] ?? []);
  }

  Future<void> atualizarCategoria(String categoriaId, String novoNome) async {
    _chamadas.add('atualizarCategoria:$categoriaId:$novoNome');
    if (_deveGerarErro) throw Exception('Erro ao atualizar categoria');
  }

  Future<void> deletarCategoria(String categoriaId) async {
    _chamadas.add('deletarCategoria:$categoriaId');
    if (_deveGerarErro) throw Exception('Erro ao deletar categoria');
  }
}

// CardapioController modificado para testes
class CardapioController {
  MockCardapioFirebase? _mockFirebase;

  // Construtor para testes
  CardapioController.paraTestar(MockCardapioFirebase mockFirebase) {
    _mockFirebase = mockFirebase;
  }

  // Construtor normal
  CardapioController();

  // Getter que retorna o mock em testes
  MockCardapioFirebase get cardapioFirebase => _mockFirebase!;

  Future<String> cadastrarCardapio(Cardapio cardapio) async {
    try {
      if (cardapio.nome.isEmpty) {
        return 'Erro: Nome do cardápio não pode estar vazio';
      }

      String? userId = cardapioFirebase.pegarIdUsuarioLogado();
      if (userId == null) {
        throw Exception('Erro: Nenhum Gerente logado');
      }

      String cardapioId = await cardapioFirebase.adicionarCardapio(userId, cardapio);
      cardapio.uid = cardapioId;

      return 'Cardápio cadastrado com sucesso';
    } catch (e) {
      throw Exception('Erro ao cadastrar cardápio: ${e.toString()}');
    }
  }

  Future<List<Cardapio>> buscarCardapios() async {
    String? userId = await cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      return await cardapioFirebase.buscarCardapios(userId);
    } catch (e) {
      throw Exception('Erro ao buscar cardápios: ${e.toString()}');
    }
  }

  Future<Stream<List<Cardapio>>> buscarCardapioTempoReal() async {
    String? userId = await cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      return Stream.value([]);
    }

    return cardapioFirebase.streamCardapios(userId);
  }

  Future<String> atualizarCardapio(Cardapio cardapio) async {
    String? userId = await cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    if (cardapio.uid == null || cardapio.uid!.isEmpty) {
      throw Exception('UID do cardápio é necessário para atualizar');
    }

    try {
      await cardapioFirebase.atualizarCardapio(userId, cardapio);
      return 'Cardápio atualizado com sucesso';
    } catch (e) {
      throw Exception('Erro ao atualizar cardápio: ${e.toString()}');
    }
  }

  Future<String> deletarCardapio(String cardapioUid) async {
    String? userId = cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await cardapioFirebase.excluirCardapio(userId, cardapioUid);
      return 'Cardápio deletado com sucesso';
    } catch (e) {
      throw Exception('Erro ao deletar cardápio: ${e.toString()}');
    }
  }

  Future<String> suspenderCardapio(String cardapioUid, bool suspender) async {
    String? userId = await cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }

    try {
      await cardapioFirebase.suspenderCardapio(userId, cardapioUid, suspender);
      return suspender
          ? 'Cardápio suspenso com sucesso'
          : 'Cardápio reativado com sucesso';
    } catch (e) {
      throw Exception('Erro ao alterar status do cardápio: ${e.toString()}');
    }
  }

  Future<Stream<List<String>>> buscarCategoriasTempoReal() async {
    String? userId = await cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      return Stream.value(['Todos', 'Bebida', 'Prato', 'Lanche', 'Outros']);
    }

    return cardapioFirebase.streamCategorias(userId).map((categorias) {
      final listaNomes = categorias.map((c) => c.nome).toList();
      final categoriasPadrao = ['Todos', 'Bebida', 'Prato', 'Lanche', 'Outros'];
      final todasCategorias = <String>{...categoriasPadrao, ...listaNomes}.toList();
      return todasCategorias;
    });
  }

  Future<void> adicionarCategoria(String nome) async {
    String? userId = cardapioFirebase.pegarIdUsuarioLogado();
    if (userId == null) {
      throw Exception('Erro: Nenhum Gerente logado');
    }
    await cardapioFirebase.adicionarCategoria(userId, nome);
  }

  Future<void> atualizarCategoria(String categoriaUid, String novoNome) async {
    await cardapioFirebase.atualizarCategoria(categoriaUid, novoNome);
  }

  Future<void> deletarCategoria(String categoriaUid) async {
    await cardapioFirebase.deletarCategoria(categoriaUid);
  }

  Future<Stream<List<Categoria>>> buscarCategoriasGerenciamento() async {
    String? userId = await cardapioFirebase.verificarGerenteUid();
    if (userId == null) {
      return Stream.value([]);
    }
    return cardapioFirebase.streamCategorias(userId);
  }
}

void main() {
  group('CardapioController Tests', () {
    late CardapioController controller;
    late MockCardapioFirebase mockCardapioFirebase;

    setUp(() {
      mockCardapioFirebase = MockCardapioFirebase();
      controller = CardapioController.paraTestar(mockCardapioFirebase);
    });

    tearDown(() {
      mockCardapioFirebase.reset();
    });

    group('cadastrarCardapio', () {
      test('deve retornar erro quando nome do cardápio está vazio', () async {
        // Arrange
        final cardapio = Cardapio(
          nome: '',
          descricao: 'Descrição teste',
          preco: 10.50,
          categoria: 'Prato',
        );

        // Act
        final resultado = await controller.cadastrarCardapio(cardapio);

        // Assert
        expect(resultado, 'Erro: Nome do cardápio não pode estar vazio');
      });

      test('deve cadastrar cardápio com sucesso', () async {
        // Arrange
        final cardapio = Cardapio(
          nome: 'Pizza Margherita',
          descricao: 'Pizza com molho de tomate e mussarela',
          preco: 25.90,
          categoria: 'Prato',
        );

        mockCardapioFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.cadastrarCardapio(cardapio);

        // Assert
        expect(resultado, 'Cardápio cadastrado com sucesso');
        expect(
          mockCardapioFirebase.chamadas,
          contains('pegarIdUsuarioLogado'),
        );
        expect(
          mockCardapioFirebase.chamadas,
          contains('adicionarCardapio:Pizza Margherita'),
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        final cardapio = Cardapio(
          nome: 'Hambúrguer',
          descricao: 'Hambúrguer artesanal',
          preco: 15.00,
        );

        mockCardapioFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.cadastrarCardapio(cardapio),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('buscarCardapios', () {
      test('deve buscar cardápios com sucesso', () async {
        // Arrange
        final cardapios = [
          Cardapio(uid: 'card1', nome: 'Pizza', descricao: 'Pizza saborosa', preco: 20.00),
          Cardapio(uid: 'card2', nome: 'Hambúrguer', descricao: 'Hambúrguer delicioso', preco: 15.00),
        ];

        mockCardapioFirebase.setGerenteUid('gerente123');
        mockCardapioFirebase.setCardapiosPorGerente('gerente123', cardapios);

        // Act
        final resultado = await controller.buscarCardapios();

        // Assert
        expect(resultado, hasLength(2));
        expect(resultado.first.nome, 'Pizza');
        expect(
          mockCardapioFirebase.chamadas,
          contains('verificarGerenteUid'),
        );
        expect(
          mockCardapioFirebase.chamadas,
          contains('buscarCardapios:gerente123'),
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockCardapioFirebase.setGerenteUid(null);

        // Act & Assert
        expect(
              () => controller.buscarCardapios(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('atualizarCardapio', () {
      test('deve atualizar cardápio com sucesso', () async {
        // Arrange
        final cardapio = Cardapio(
          uid: 'card123',
          nome: 'Pizza Atualizada',
          descricao: 'Nova descrição',
          preco: 30.00,
        );

        mockCardapioFirebase.setGerenteUid('gerente123');

        // Act
        final resultado = await controller.atualizarCardapio(cardapio);

        // Assert
        expect(resultado, 'Cardápio atualizado com sucesso');
        expect(
          mockCardapioFirebase.chamadas,
          contains('atualizarCardapio:card123'),
        );
      });

      test('deve lançar exceção quando UID do cardápio é nulo', () async {
        // Arrange
        final cardapio = Cardapio(
          nome: 'Pizza',
          descricao: 'Descrição',
          preco: 20.00,
        );

        mockCardapioFirebase.setGerenteUid('gerente123');

        // Act & Assert
        expect(
              () => controller.atualizarCardapio(cardapio),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        final cardapio = Cardapio(
          uid: 'card123',
          nome: 'Pizza',
          descricao: 'Descrição',
          preco: 20.00,
        );

        mockCardapioFirebase.setGerenteUid(null);

        // Act & Assert
        expect(
              () => controller.atualizarCardapio(cardapio),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deletarCardapio', () {
      test('deve deletar cardápio com sucesso', () async {
        // Arrange
        const cardapioUid = 'card123';
        mockCardapioFirebase.setUsuarioLogado('gerente123');

        // Act
        final resultado = await controller.deletarCardapio(cardapioUid);

        // Assert
        expect(resultado, 'Cardápio deletado com sucesso');
        expect(
          mockCardapioFirebase.chamadas,
          contains('excluirCardapio:card123'),
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockCardapioFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.deletarCardapio('card123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('suspenderCardapio', () {
      test('deve suspender cardápio com sucesso', () async {
        const cardapioUid = 'card123';
        mockCardapioFirebase.setGerenteUid('gerente123');

        final resultado = await controller.suspenderCardapio(cardapioUid, true);

        expect(resultado, 'Cardápio suspenso com sucesso');
        expect(
          mockCardapioFirebase.chamadas,
          contains('suspenderCardapio:card123:true'), // corrigido
        );
      });

      test('deve reativar cardápio com sucesso', () async {
        const cardapioUid = 'card123';
        mockCardapioFirebase.setGerenteUid('gerente123');

        final resultado = await controller.suspenderCardapio(cardapioUid, false);

        expect(resultado, 'Cardápio reativado com sucesso');
        expect(
          mockCardapioFirebase.chamadas,
          contains('suspenderCardapio:card123:false'), // corrigido
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockCardapioFirebase.setGerenteUid(null);

        // Act & Assert
        expect(
              () => controller.suspenderCardapio('card123', false),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('adicionarCategoria', () {
      test('deve adicionar categoria com sucesso', () async {
        // Arrange
        const nomeCategoria = 'Sobremesas';
        mockCardapioFirebase.setUsuarioLogado('gerente123');

        // Act
        await controller.adicionarCategoria(nomeCategoria);

        // Assert
        expect(
          mockCardapioFirebase.chamadas,
          contains('adicionarCategoria:Sobremesas'),
        );
      });

      test('deve lançar exceção quando nenhum gerente está logado', () async {
        // Arrange
        mockCardapioFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.adicionarCategoria('Sobremesas'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('atualizarCategoria', () {
      test('deve atualizar categoria com sucesso', () async {
        // Arrange
        const categoriaUid = 'cat123';
        const novoNome = 'Nova Categoria';

        // Act
        await controller.atualizarCategoria(categoriaUid, novoNome);

        // Assert
        expect(
          mockCardapioFirebase.chamadas,
          contains('atualizarCategoria:cat123:Nova Categoria'),
        );
      });
    });

    group('deletarCategoria', () {
      test('deve deletar categoria com sucesso', () async {
        // Arrange
        const categoriaUid = 'cat123';

        // Act
        await controller.deletarCategoria(categoriaUid);

        // Assert
        expect(
          mockCardapioFirebase.chamadas,
          contains('deletarCategoria:cat123'),
        );
      });
    });

    group('buscarCategoriasTempoReal', () {
      test('deve retornar categorias padrão quando nenhum gerente está logado', () async {
        // Arrange
        mockCardapioFirebase.setGerenteUid(null);

        // Act
        final streamCategorias = await controller.buscarCategoriasTempoReal();
        final categorias = await streamCategorias.first;

        // Assert
        expect(categorias, contains('Todos'));
        expect(categorias, contains('Bebida'));
        expect(categorias, contains('Prato'));
        expect(categorias, contains('Lanche'));
        expect(categorias, contains('Outros'));
      });

      test('deve combinar categorias padrão com categorias do gerente', () async {
        // Arrange
        final categoriasDoGerente = [
          Categoria(uid: 'cat1', nome: 'Sobremesas'),
          Categoria(uid: 'cat2', nome: 'Entradas'),
        ];

        mockCardapioFirebase.setGerenteUid('gerente123');
        mockCardapioFirebase.setCategoriasPorGerente('gerente123', categoriasDoGerente);

        // Act
        final streamCategorias = await controller.buscarCategoriasTempoReal();
        final categorias = await streamCategorias.first;

        // Assert
        expect(categorias, contains('Sobremesas'));
        expect(categorias, contains('Entradas'));
        expect(categorias, contains('Todos'));
        expect(categorias, contains('Bebida'));
      });
    });
  });

  group('Testes de Validação de Cardapio', () {
    test('deve criar um cardápio válido', () {
      // Arrange & Act
      final cardapio = Cardapio(
        nome: 'Pizza Margherita',
        descricao: 'Pizza com molho de tomate e mussarela',
        preco: 25.90,
        categoria: 'Prato',
      );

      // Assert
      expect(cardapio.nome, 'Pizza Margherita');
      expect(cardapio.descricao, 'Pizza com molho de tomate e mussarela');
      expect(cardapio.preco, 25.90);
      expect(cardapio.categoria, 'Prato');
      expect(cardapio.ativo, true);
    });

    test('deve validar preço positivo', () {
      final cardapio = Cardapio(
        nome: 'Hambúrguer',
        descricao: 'Hambúrguer artesanal',
        preco: 15.50,
      );

      expect(cardapio.preco, greaterThan(0));
    });

    test('deve ter categoria padrão "Outros" quando não especificada', () {
      final cardapio = Cardapio(
        nome: 'Item teste',
        descricao: 'Descrição teste',
        preco: 10.00,
      );

      expect(cardapio.categoria, 'Outros');
    });

    test('deve estar ativo por padrão', () {
      final cardapio = Cardapio(
        nome: 'Item teste',
        descricao: 'Descrição teste',
        preco: 10.00,
      );

      expect(cardapio.ativo, true);
    });

    test('deve converter para Map corretamente', () {
      final cardapio = Cardapio(
        nome: 'Pizza',
        descricao: 'Pizza deliciosa',
        preco: 20.00,
        categoria: 'Prato',
        ativo: false,
      );

      final map = cardapio.toMap();

      expect(map['nome'], 'Pizza');
      expect(map['descricao'], 'Pizza deliciosa');
      expect(map['preco'], 20.00);
      expect(map['categoria'], 'Prato');
      expect(map['ativo'], false);
    });

    test('deve criar cardápio a partir de Map corretamente', () {
      final map = {
        'nome': 'Hambúrguer',
        'descricao': 'Hambúrguer saboroso',
        'preco': 15.0,
        'categoria': 'Lanche',
        'ativo': true,
      };

      final cardapio = Cardapio.fromMap('card123', map);

      expect(cardapio.uid, 'card123');
      expect(cardapio.nome, 'Hambúrguer');
      expect(cardapio.descricao, 'Hambúrguer saboroso');
      expect(cardapio.preco, 15.0);
      expect(cardapio.categoria, 'Lanche');
      expect(cardapio.ativo, true);
    });

    test('deve usar valores padrão quando campos estão ausentes no Map', () {
      final map = <String, dynamic>{}; // Map vazio

      final cardapio = Cardapio.fromMap('card123', map);

      expect(cardapio.uid, 'card123');
      expect(cardapio.nome, '');
      expect(cardapio.descricao, '');
      expect(cardapio.preco, 0.0);
      expect(cardapio.categoria, 'Outros');
      expect(cardapio.ativo, true);
    });
  });

  group('Testes de Validação de Categoria', () {
    test('deve criar uma categoria válida', () {
      // Arrange & Act
      final categoria = Categoria(
        uid: 'cat123',
        nome: 'Sobremesas',
      );

      // Assert
      expect(categoria.uid, 'cat123');
      expect(categoria.nome, 'Sobremesas');
    });

    test('deve criar categoria a partir de Map corretamente', () {
      final map = {
        'nome': 'Entradas',
      };

      final categoria = Categoria.fromMap('cat456', map);

      expect(categoria.uid, 'cat456');
      expect(categoria.nome, 'Entradas');
    });

    test('deve usar nome vazio quando ausente no Map', () {
      final map = <String, dynamic>{};

      final categoria = Categoria.fromMap('cat789', map);

      expect(categoria.uid, 'cat789');
      expect(categoria.nome, '');
    });
  });
}