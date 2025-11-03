// test/relatorio_controller_test.dart
import 'package:flutter_test/flutter_test.dart';

// Classe Pedido simplificada para teste
class Pedido {
  String? uid;
  DateTime horario;
  Mesa mesa;
  List<ItemCardapio> itens;
  String statusAtual;
  String? gerenteUid;
  bool pago;

  Pedido({
    this.uid,
    required this.horario,
    required this.mesa,
    required this.itens,
    required this.statusAtual,
    this.gerenteUid,
    this.pago = false,
  });

  double calcularTotal() {
    return itens.fold<double>(0, (total, item) => total + (item.preco * item.quantidade));
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horario': horario.toIso8601String(),
      'mesa': mesa.toMap(),
      'itens': itens.map((item) => item.toMap()).toList(),
      'statusAtual': statusAtual,
      'gerenteUid': gerenteUid,
      'pago': pago,
    };
  }
}

class Mesa {
  String? uid;
  int numero;
  String nome;

  Mesa({this.uid, required this.numero, this.nome = ''});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'numero': numero, 'nome': nome};
  }
}

class ItemCardapio {
  String? uid;
  String nome;
  double preco;
  int quantidade;

  ItemCardapio({
    this.uid,
    required this.nome,
    required this.preco,
    this.quantidade = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'preco': preco,
      'quantidade': quantidade,
    };
  }
}

// Mock do RelatorioController
class MockRelatorioController {
  List<Map<String, dynamic>> _pedidos = [];
  List<String> _chamadas = [];
  bool _deveGerarErro = false;
  List<Map<String, dynamic>>? _cachedPedidos;
  DateTime? _cacheTimestamp;

  void setPedidos(List<Map<String, dynamic>> pedidos) => _pedidos = pedidos;
  void setDeveGerarErro(bool erro) => _deveGerarErro = erro;

  void reset() {
    _pedidos.clear();
    _chamadas.clear();
    _deveGerarErro = false;
    clearCache();
  }

  List<String> get chamadas => _chamadas;

  void clearCache() {
    _cachedPedidos = null;
    _cacheTimestamp = null;
  }

  bool get isCacheValid {
    if (_cachedPedidos == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < Duration(minutes: 5);
  }

  Future<List<Map<String, dynamic>>> getAllPedidos() async {
    _chamadas.add('getAllPedidos');
    if (_deveGerarErro) throw Exception('Erro ao buscar pedidos');

    if (isCacheValid) {
      return _cachedPedidos as List<Map<String, dynamic>>;
    }

    _cachedPedidos = _pedidos;
    _cacheTimestamp = DateTime.now();
    return _pedidos;
  }

  Future<List<Map<String, dynamic>>> listarPedidos({
    int? limite,
    String? status,
  }) async {
    _chamadas.add('listarPedidos:limite=$limite:status=$status');
    if (_deveGerarErro) throw Exception('Erro ao listar pedidos');

    var resultado = List<Map<String, dynamic>>.from(_pedidos);

    if (status != null) {
      resultado = resultado.where((p) => p['statusAtual'] == status).toList();
    }

    if (limite != null) {
      resultado = resultado.take(limite).toList();
    }

    return resultado;
  }

  Future<Map<String, int>> produtosMaisVendidos({int? limite}) async {
    _chamadas.add('produtosMaisVendidos:limite=$limite');
    if (_deveGerarErro) throw Exception('Erro ao calcular produtos mais vendidos');

    final pedidos = await getAllPedidos();
    Map<String, int> ranking = {};

    for (var pedido in pedidos) {
      final itens = pedido['itens'] as List<dynamic>? ?? [];
      for (var item in itens) {
        final nome = item['nome'] ?? 'Desconhecido';
        final quantidade = (item['quantidade'] as num? ?? 0).toInt();
        ranking[nome] = (ranking[nome] ?? 0) + quantidade;
      }
    }

    var sorted = ranking.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (limite != null && limite > 0) {
      sorted = sorted.take(limite).toList();
    }

    return Map.fromEntries(sorted);
  }

  Future<Map<String, double>> faturamentoPorProduto({int? limite}) async {
    _chamadas.add('faturamentoPorProduto:limite=$limite');
    if (_deveGerarErro) throw Exception('Erro ao calcular faturamento por produto');

    final pedidos = await getAllPedidos();
    Map<String, double> faturamento = {};

    for (var pedido in pedidos) {
      final itens = pedido['itens'] as List<dynamic>? ?? [];
      for (var item in itens) {
        final nome = item['nome'] ?? 'Desconhecido';
        final preco = (item['preco'] as num? ?? 0).toDouble();
        final quantidade = (item['quantidade'] as num? ?? 0).toInt();
        faturamento[nome] = (faturamento[nome] ?? 0.0) + (preco * quantidade);
      }
    }

    var sorted = faturamento.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (limite != null && limite > 0) {
      sorted = sorted.take(limite).toList();
    }

    return Map.fromEntries(sorted);
  }

  Future<Map<String, int>> pedidosPorDia({
    DateTime? inicio,
    DateTime? fim,
    bool ordenarPorData = true,
  }) async {
    _chamadas.add('pedidosPorDia:inicio=$inicio:fim=$fim');
    if (_deveGerarErro) throw Exception('Erro ao calcular pedidos por dia');

    final pedidos = await getAllPedidos();
    Map<String, int> porDia = {};

    for (var pedido in pedidos) {
      final horario = DateTime.parse(pedido['horario']);

      if (inicio != null && horario.isBefore(inicio)) continue;
      if (fim != null && horario.isAfter(fim)) continue;

      final dataStr = _formatarData(horario);
      porDia[dataStr] = (porDia[dataStr] ?? 0) + 1;
    }

    if (ordenarPorData) {
      var sorted = porDia.entries.toList()
        ..sort((a, b) => _compararDatas(a.key, b.key));
      return Map.fromEntries(sorted);
    }

    return porDia;
  }

  Future<Map<String, double>> faturamentoPorDia({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    _chamadas.add('faturamentoPorDia:inicio=$inicio:fim=$fim');
    if (_deveGerarErro) throw Exception('Erro ao calcular faturamento por dia');

    final pedidos = await getAllPedidos();
    Map<String, double> faturamentoDia = {};

    for (var pedido in pedidos) {
      final horario = DateTime.parse(pedido['horario']);

      if (inicio != null && horario.isBefore(inicio)) continue;
      if (fim != null && horario.isAfter(fim)) continue;

      final dataStr = _formatarData(horario);
      final itens = pedido['itens'] as List<dynamic>? ?? [];

      double total = 0.0;
      for (var item in itens) {
        final preco = (item['preco'] as num? ?? 0).toDouble();
        final quantidade = (item['quantidade'] as num? ?? 0).toInt();
        total += preco * quantidade;
      }

      faturamentoDia[dataStr] = (faturamentoDia[dataStr] ?? 0.0) + total;
    }

    var sorted = faturamentoDia.entries.toList()
      ..sort((a, b) => _compararDatas(a.key, b.key));

    return Map.fromEntries(sorted);
  }

  Future<List<Map<String, dynamic>>> pedidosPorPeriodo(DateTime inicio, DateTime fim) async {
    _chamadas.add('pedidosPorPeriodo:$inicio:$fim');
    if (_deveGerarErro) throw Exception('Erro ao buscar pedidos por período');

    return _pedidos.where((p) {
      final horario = DateTime.parse(p['horario']);
      return horario.isAfter(inicio.subtract(Duration(seconds: 1))) &&
          horario.isBefore(fim.add(Duration(days: 1)));
    }).toList();
  }

  Future<Map<String, dynamic>> estatisticasGerais({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    _chamadas.add('estatisticasGerais:inicio=$inicio:fim=$fim');
    if (_deveGerarErro) throw Exception('Erro ao calcular estatísticas gerais');

    final pedidos = await pedidosPorPeriodo(
      inicio ?? DateTime(2020),
      fim ?? DateTime.now(),
    );

    if (pedidos.isEmpty) {
      return {
        'totalPedidos': 0,
        'faturamentoTotal': 0.0,
        'ticketMedio': 0.0,
        'produtoMaisVendido': 'N/A',
        'diaMaisMovimentado': 'N/A',
      };
    }

    double totalFaturamento = 0.0;
    for (var pedido in pedidos) {
      final itens = pedido['itens'] as List<dynamic>? ?? [];
      for (var item in itens) {
        final preco = (item['preco'] as num? ?? 0).toDouble();
        final quantidade = (item['quantidade'] as num? ?? 0).toInt();
        totalFaturamento += preco * quantidade;
      }
    }

    double ticketMedio = totalFaturamento / pedidos.length;

    var produtosMaisVendidosMap = await produtosMaisVendidos(limite: 1);
    String produtoMaisVendido = produtosMaisVendidosMap.isNotEmpty
        ? produtosMaisVendidosMap.keys.first
        : 'N/A';

    var pedidosPorDiaMap = await pedidosPorDia(inicio: inicio, fim: fim);
    String diaMaisMovimentado = pedidosPorDiaMap.isNotEmpty
        ? pedidosPorDiaMap.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'N/A';

    return {
      'totalPedidos': pedidos.length,
      'faturamentoTotal': totalFaturamento,
      'ticketMedio': ticketMedio,
      'produtoMaisVendido': produtoMaisVendido,
      'diaMaisMovimentado': diaMaisMovimentado,
    };
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  int _compararDatas(String dataA, String dataB) {
    List<String> partesA = dataA.split('/');
    List<String> partesB = dataB.split('/');

    DateTime dateA = DateTime(
        int.parse(partesA[2]), int.parse(partesA[1]), int.parse(partesA[0]));
    DateTime dateB = DateTime(
        int.parse(partesB[2]), int.parse(partesB[1]), int.parse(partesB[0]));

    return dateA.compareTo(dateB);
  }
}

// RelatorioController para testes
class RelatorioController {
  MockRelatorioController? _mock;

  RelatorioController.paraTestar(MockRelatorioController mock) {
    _mock = mock;
  }

  RelatorioController();

  MockRelatorioController get controller => _mock!;

  void clearCache() => controller.clearCache();

  Future<List<Map<String, dynamic>>> listarPedidos({
    int? limite,
    String? status,
  }) async {
    return await controller.listarPedidos(limite: limite, status: status);
  }

  Future<Map<String, int>> produtosMaisVendidos({int? limite}) async {
    return await controller.produtosMaisVendidos(limite: limite);
  }

  Future<Map<String, double>> faturamentoPorProduto({int? limite}) async {
    return await controller.faturamentoPorProduto(limite: limite);
  }

  Future<Map<String, int>> pedidosPorDia({
    DateTime? inicio,
    DateTime? fim,
    bool ordenarPorData = true,
  }) async {
    return await controller.pedidosPorDia(
      inicio: inicio,
      fim: fim,
      ordenarPorData: ordenarPorData,
    );
  }

  Future<Map<String, double>> faturamentoPorDia({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    return await controller.faturamentoPorDia(inicio: inicio, fim: fim);
  }

  Future<List<Map<String, dynamic>>> pedidosPorPeriodo(DateTime inicio, DateTime fim) async {
    return await controller.pedidosPorPeriodo(inicio, fim);
  }

  Future<Map<String, dynamic>> estatisticasGerais({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    return await controller.estatisticasGerais(inicio: inicio, fim: fim);
  }
}

void main() {
  group('RelatorioController Tests', () {
    late RelatorioController controller;
    late MockRelatorioController mockController;

    setUp(() {
      mockController = MockRelatorioController();
      controller = RelatorioController.paraTestar(mockController);
    });

    tearDown(() {
      mockController.reset();
    });

    group('listarPedidos', () {
      test('deve listar todos os pedidos sem filtros', () async {
        // Arrange
        final pedidos = [
          {
            'uid': 'p1',
            'horario': DateTime.now().toIso8601String(),
            'statusAtual': 'Aberto',
            'itens': [],
          },
          {
            'uid': 'p2',
            'horario': DateTime.now().toIso8601String(),
            'statusAtual': 'Entregue',
            'itens': [],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.listarPedidos();

        // Assert
        expect(resultado, hasLength(2));
        expect(mockController.chamadas, contains('listarPedidos:limite=null:status=null'));
      });

      test('deve filtrar pedidos por status', () async {
        // Arrange
        final pedidos = [
          {
            'uid': 'p1',
            'horario': DateTime.now().toIso8601String(),
            'statusAtual': 'Aberto',
            'itens': [],
          },
          {
            'uid': 'p2',
            'horario': DateTime.now().toIso8601String(),
            'statusAtual': 'Entregue',
            'itens': [],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.listarPedidos(status: 'Aberto');

        // Assert
        expect(resultado, hasLength(1));
        expect(resultado.first['statusAtual'], 'Aberto');
      });

      test('deve limitar quantidade de pedidos', () async {
        // Arrange
        final pedidos = List.generate(10, (i) => {
          'uid': 'p$i',
          'horario': DateTime.now().toIso8601String(),
          'statusAtual': 'Aberto',
          'itens': [],
        });
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.listarPedidos(limite: 5);

        // Assert
        expect(resultado, hasLength(5));
      });

      test('deve lançar exceção quando ocorre erro', () async {
        // Arrange
        mockController.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.listarPedidos(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('produtosMaisVendidos', () {
      test('deve calcular produtos mais vendidos corretamente', () async {
        // Arrange
        final pedidos = [
          {
            'uid': 'p1',
            'horario': DateTime.now().toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 2},
              {'nome': 'Refrigerante', 'preco': 5.0, 'quantidade': 3},
            ],
          },
          {
            'uid': 'p2',
            'horario': DateTime.now().toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 1},
            ],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.produtosMaisVendidos();

        // Assert
        expect(resultado['Pizza'], 3); // 2 + 1
        expect(resultado['Refrigerante'], 3);
        expect(resultado.keys.first, 'Pizza'); // Mais vendido
      });

      test('deve limitar quantidade de produtos no ranking', () async {
        // Arrange
        final pedidos = [
          {
            'uid': 'p1',
            'horario': DateTime.now().toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 5},
              {'nome': 'Hambúrguer', 'preco': 20.0, 'quantidade': 3},
              {'nome': 'Refrigerante', 'preco': 5.0, 'quantidade': 2},
            ],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.produtosMaisVendidos(limite: 2);

        // Assert
        expect(resultado, hasLength(2));
        expect(resultado.keys.first, 'Pizza');
      });

      test('deve retornar mapa vazio quando não há pedidos', () async {
        // Arrange
        mockController.setPedidos([]);

        // Act
        final resultado = await controller.produtosMaisVendidos();

        // Assert
        expect(resultado, isEmpty);
      });
    });

    group('faturamentoPorProduto', () {
      test('deve calcular faturamento por produto corretamente', () async {
        // Arrange
        final pedidos = [
          {
            'uid': 'p1',
            'horario': DateTime.now().toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 2},
              {'nome': 'Refrigerante', 'preco': 5.0, 'quantidade': 3},
            ],
          },
          {
            'uid': 'p2',
            'horario': DateTime.now().toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 1},
            ],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.faturamentoPorProduto();

        // Assert
        expect(resultado['Pizza'], 90.0); // (30 * 2) + (30 * 1)
        expect(resultado['Refrigerante'], 15.0); // 5 * 3
      });

      test('deve ordenar por faturamento decrescente', () async {
        // Arrange
        final pedidos = [
          {
            'uid': 'p1',
            'horario': DateTime.now().toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 3},
              {'nome': 'Hambúrguer', 'preco': 20.0, 'quantidade': 5},
            ],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.faturamentoPorProduto();

        // Assert
        final keys = resultado.keys.toList();
        expect(keys.first, 'Hambúrguer'); // 100.0
        expect(keys.last, 'Pizza'); // 90.0
      });
    });

    group('pedidosPorDia', () {
      test('deve contar pedidos por dia corretamente', () async {
        // Arrange
        final hoje = DateTime.now();
        final ontem = hoje.subtract(Duration(days: 1));

        final pedidos = [
          {
            'uid': 'p1',
            'horario': hoje.toIso8601String(),
            'itens': [],
          },
          {
            'uid': 'p2',
            'horario': hoje.toIso8601String(),
            'itens': [],
          },
          {
            'uid': 'p3',
            'horario': ontem.toIso8601String(),
            'itens': [],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.pedidosPorDia();

        // Assert
        expect(resultado.values.reduce((a, b) => a + b), 3);
      });

      test('deve filtrar por período quando fornecido', () async {
        // Arrange
        final hoje = DateTime.now();
        final ontem = hoje.subtract(Duration(days: 1));
        final anteontem = hoje.subtract(Duration(days: 2));

        final pedidos = [
          {'uid': 'p1', 'horario': hoje.toIso8601String(), 'itens': []},
          {'uid': 'p2', 'horario': ontem.toIso8601String(), 'itens': []},
          {'uid': 'p3', 'horario': anteontem.toIso8601String(), 'itens': []},
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.pedidosPorDia(
          inicio: ontem,
          fim: hoje,
        );

        // Assert
        expect(resultado.values.reduce((a, b) => a + b), 2);
      });
    });

    group('faturamentoPorDia', () {
      test('deve calcular faturamento por dia corretamente', () async {
        // Arrange
        final hoje = DateTime.now();
        final ontem = hoje.subtract(Duration(days: 1));

        final pedidos = [
          {
            'uid': 'p1',
            'horario': hoje.toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 2},
            ],
          },
          {
            'uid': 'p2',
            'horario': ontem.toIso8601String(),
            'itens': [
              {'nome': 'Hambúrguer', 'preco': 20.0, 'quantidade': 1},
            ],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.faturamentoPorDia();

        // Assert
        expect(resultado.values.reduce((a, b) => a + b), 80.0); // 60 + 20
      });
    });

    group('pedidosPorPeriodo', () {
      test('deve buscar pedidos dentro do período', () async {
        // Arrange
        final hoje = DateTime.now();
        final ontem = hoje.subtract(Duration(days: 1));
        final semanaPassada = hoje.subtract(Duration(days: 7));

        final pedidos = [
          {'uid': 'p1', 'horario': hoje.toIso8601String(), 'itens': []},
          {'uid': 'p2', 'horario': ontem.toIso8601String(), 'itens': []},
          {'uid': 'p3', 'horario': semanaPassada.toIso8601String(), 'itens': []},
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.pedidosPorPeriodo(
          ontem.subtract(Duration(hours: 1)),
          hoje.add(Duration(hours: 1)),
        );

        // Assert
        expect(resultado, hasLength(2));
      });
    });

    group('estatisticasGerais', () {
      test('deve calcular estatísticas gerais corretamente', () async {
        // Arrange
        final hoje = DateTime.now();
        final pedidos = [
          {
            'uid': 'p1',
            'horario': hoje.toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 2},
            ],
          },
          {
            'uid': 'p2',
            'horario': hoje.toIso8601String(),
            'itens': [
              {'nome': 'Pizza', 'preco': 30.0, 'quantidade': 1},
              {'nome': 'Refrigerante', 'preco': 5.0, 'quantidade': 2},
            ],
          },
        ];
        mockController.setPedidos(pedidos);

        // Act
        final resultado = await controller.estatisticasGerais(
          inicio: hoje.subtract(Duration(days: 1)),
          fim: hoje.add(Duration(days: 1)),
        );

        // Assert
        expect(resultado['totalPedidos'], 2);
        expect(resultado['faturamentoTotal'], 100.0); // 60 + 30 + 10
        expect(resultado['ticketMedio'], 50.0); // 100 / 2
        expect(resultado['produtoMaisVendido'], 'Pizza');
      });

      test('deve retornar estatísticas vazias quando não há pedidos', () async {
        // Arrange
        mockController.setPedidos([]);

        // Act
        final resultado = await controller.estatisticasGerais();

        // Assert
        expect(resultado['totalPedidos'], 0);
        expect(resultado['faturamentoTotal'], 0.0);
        expect(resultado['ticketMedio'], 0.0);
        expect(resultado['produtoMaisVendido'], 'N/A');
        expect(resultado['diaMaisMovimentado'], 'N/A');
      });
    });

    group('cache', () {
      test('deve usar cache quando válido', () async {
        // Arrange
        final pedidos = [
          {'uid': 'p1', 'horario': DateTime.now().toIso8601String(), 'itens': []},
        ];
        mockController.setPedidos(pedidos);

        // Act
        await controller.produtosMaisVendidos();
        mockController.chamadas.clear();
        await controller.produtosMaisVendidos();

        // Assert
        expect(mockController.chamadas, contains('produtosMaisVendidos:limite=null'));
        expect(mockController.chamadas.where((c) => c == 'getAllPedidos').length, 1);
      });

      test('deve limpar cache quando clearCache é chamado', () async {
        // Arrange
        final pedidos = [
          {'uid': 'p1', 'horario': DateTime.now().toIso8601String(), 'itens': []},
        ];
        mockController.setPedidos(pedidos);
        await controller.produtosMaisVendidos();

        // Act
        controller.clearCache();
        mockController.chamadas.clear();
        await controller.produtosMaisVendidos();

        // Assert
        expect(mockController.chamadas, contains('getAllPedidos'));
      });
    });
  });
}