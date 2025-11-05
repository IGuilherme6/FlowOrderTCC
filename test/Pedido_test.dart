// test/pedido_controller_test.dart
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
}

// Classe ItemCardapio para teste
class ItemCardapio {
  String? uid;
  String nome;
  double preco;
  int quantidade;
  String? observacao;

  ItemCardapio({
    this.uid,
    required this.nome,
    required this.preco,
    this.quantidade = 1,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'preco': preco,
      'quantidade': quantidade,
      'observacao': observacao,
    };
  }

  factory ItemCardapio.fromMap(Map<String, dynamic> map, String documentId) {
    return ItemCardapio(
      uid: documentId,
      nome: map['nome'] ?? '',
      preco: (map['preco'] ?? 0).toDouble(),
      quantidade: map['quantidade'] ?? 1,
      observacao: map['observacao'],
    );
  }
}

// Classe Pedido para teste
class Pedido {
  String? uid;
  DateTime horario;
  Mesa mesa;
  List<ItemCardapio> itens;
  String statusAtual;
  String? observacao;
  String? gerenteUid;
  bool pago;

  static const List<String> statusOpcoes = [
    'Aberto',
    'Em Preparo',
    'Pronto',
    'Entregue',
    'Cancelado'
  ];

  Pedido({
    this.uid,
    required this.horario,
    required this.mesa,
    required this.itens,
    required this.statusAtual,
    this.observacao,
    this.gerenteUid,
    this.pago = false,
  });

  double calcularTotal() {
    return itens.fold<double>(0, (total, item) => total + (item.preco * item.quantidade));
  }

  double get total => calcularTotal();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horario': horario.toIso8601String(),
      'mesa': mesa.toMap(),
      'itens': itens.map((item) => item.toMap()).toList(),
      'statusAtual': statusAtual,
      'observacao': observacao,
      'gerenteUid': gerenteUid,
      'pago': pago,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map, String documentId) {
    return Pedido(
      uid: documentId,
      horario: DateTime.parse(map['horario']),
      mesa: Mesa.fromMap(map['mesa'] as Map<String, dynamic>, map['mesa']['uid'] ?? ''),
      itens: (map['itens'] as List<dynamic>)
          .map((item) => ItemCardapio.fromMap(item as Map<String, dynamic>, item['uid'] ?? ''))
          .toList(),
      statusAtual: map['statusAtual'] ?? 'Aberto',
      observacao: map['observacao'] ?? '',
      gerenteUid: map['gerenteUid'],
      pago: map['pago'] ?? false,
    );
  }

  Pedido copyWith({
    String? uid,
    DateTime? horario,
    Mesa? mesa,
    List<ItemCardapio>? itens,
    String? statusAtual,
    String? observacao,
    String? gerenteUid,
    bool? pago,
  }) {
    return Pedido(
      uid: uid ?? this.uid,
      horario: horario ?? this.horario,
      mesa: mesa ?? this.mesa,
      itens: itens ?? this.itens,
      statusAtual: statusAtual ?? this.statusAtual,
      observacao: observacao ?? this.observacao,
      gerenteUid: gerenteUid ?? this.gerenteUid,
      pago: pago ?? this.pago,
    );
  }
}

// Mock do PedidoFirebase
class MockPedidoFirebase {
  String? _usuarioLogado;
  String? _gerenteUid;
  Map<String, Pedido> _pedidos = {};
  Map<String, Map<String, dynamic>> _detalhesPagamento = {};
  Map<String, bool> _senhasGerentes = {};
  List<String> _chamadas = [];
  bool _deveGerarErro = false;

  void setUsuarioLogado(String? id) => _usuarioLogado = id;
  void setGerenteUid(String? id) => _gerenteUid = id;
  void setPedido(String uid, Pedido pedido) => _pedidos[uid] = pedido;
  void setDetalhePagamento(String pedidoUid, Map<String, dynamic> detalhe) =>
      _detalhesPagamento[pedidoUid] = detalhe;
  void setSenhaGerente(String gerenteUid, String senha, bool valida) =>
      _senhasGerentes['$gerenteUid:$senha'] = valida;
  void setDeveGerarErro(bool erro) => _deveGerarErro = erro;

  void reset() {
    _usuarioLogado = null;
    _gerenteUid = null;
    _pedidos.clear();
    _detalhesPagamento.clear();
    _senhasGerentes.clear();
    _chamadas.clear();
    _deveGerarErro = false;
  }

  List<String> get chamadas => _chamadas;

  String? pegarIdUsuarioLogado() {
    _chamadas.add('pegarIdUsuarioLogado');
    return _usuarioLogado;
  }

  Future<String?> pegarGerenteUid(String uid) async {
    _chamadas.add('pegarGerenteUid:$uid');
    if (_deveGerarErro) throw Exception('Erro ao buscar gerente');
    return _gerenteUid;
  }

  Future<String> adicionarPedido(Pedido pedido) async {
    _chamadas.add('adicionarPedido');
    if (_deveGerarErro) throw Exception('Erro ao adicionar pedido');

    final pedidoId = 'pedido_${DateTime.now().millisecondsSinceEpoch}';
    pedido.uid = pedidoId;
    _pedidos[pedidoId] = pedido;
    return pedidoId;
  }

  Future<void> atualizarStatus(String pedidoId, String novoStatus) async {
    _chamadas.add('atualizarStatus:$pedidoId:$novoStatus');
    if (_deveGerarErro) throw Exception('Erro ao atualizar status');

    final pedido = _pedidos[pedidoId];
    if (pedido != null) {
      _pedidos[pedidoId] = pedido.copyWith(statusAtual: novoStatus);
    }
  }

  Stream<List<Pedido>> ouvirPedidosTempoReal(String gerenteUid) {
    _chamadas.add('ouvirPedidosTempoReal:$gerenteUid');
    if (_deveGerarErro) return Stream.error(Exception('Erro no stream'));

    final pedidosDoGerente = _pedidos.values
        .where((p) => p.gerenteUid == gerenteUid && !p.pago)
        .toList();
    return Stream.value(pedidosDoGerente);
  }

  Future<void> marcarComoPago({
    required String pedidoUid,
    required String metodoPagamento,
    required double valorPago,
    required double desconto,
    required double troco,
  }) async {
    _chamadas.add('marcarComoPago:$pedidoUid');
    if (_deveGerarErro) throw Exception('Erro ao marcar como pago');

    final pedido = _pedidos[pedidoUid];
    if (pedido != null) {
      _pedidos[pedidoUid] = pedido.copyWith(pago: true);
      _detalhesPagamento[pedidoUid] = {
        'metodoPagamento': metodoPagamento,
        'valorPago': valorPago,
        'desconto': desconto,
        'troco': troco,
      };
    }
  }

  Future<Pedido?> buscarPedidoPorUid(String uid) async {
    _chamadas.add('buscarPedidoPorUid:$uid');
    if (_deveGerarErro) throw Exception('Erro ao buscar pedido');
    return _pedidos[uid];
  }

  Future<bool> verificarSenhaGerente(String gerenteUid, String senha) async {
    _chamadas.add('verificarSenhaGerente:$gerenteUid');
    if (_deveGerarErro) throw Exception('Erro ao verificar senha');
    return _senhasGerentes['$gerenteUid:$senha'] ?? false;
  }

  Future<void> excluirPedido(String pedidoUid) async {
    _chamadas.add('excluirPedido:$pedidoUid');
    if (_deveGerarErro) throw Exception('Erro ao excluir pedido');

    final pedido = _pedidos[pedidoUid];
    if (pedido != null) {
      _pedidos[pedidoUid] = pedido.copyWith(statusAtual: 'Cancelado');
    }
  }

  Future<void> editarPedido(String uid, Map<String, dynamic> dados) async {
    _chamadas.add('editarPedido:$uid');
    if (_deveGerarErro) throw Exception('Erro ao editar pedido');

    final pedido = Pedido.fromMap(dados, uid);
    _pedidos[uid] = pedido;
  }

  Future<List<Pedido>> buscarPedidosDoDia(DateTime dia) async {
    _chamadas.add('buscarPedidosDoDia');
    if (_deveGerarErro) throw Exception('Erro ao buscar pedidos do dia');

    return _pedidos.values
        .where((p) =>
    p.horario.year == dia.year &&
        p.horario.month == dia.month &&
        p.horario.day == dia.day)
        .toList();
  }

  Future<List<Pedido>> buscarPedidosPorPeriodo(DateTime inicio, DateTime fim) async {
    _chamadas.add('buscarPedidosPorPeriodo');
    if (_deveGerarErro) throw Exception('Erro ao buscar pedidos por período');

    return _pedidos.values
        .where((p) =>
    p.horario.isAfter(inicio.subtract(Duration(seconds: 1))) &&
        p.horario.isBefore(fim.add(Duration(seconds: 1))))
        .toList();
  }

  Future<Map<String, dynamic>?> buscarDetalhePagamento(String pedidoUid) async {
    _chamadas.add('buscarDetalhePagamento:$pedidoUid');
    if (_deveGerarErro) throw Exception('Erro ao buscar detalhe pagamento');
    return _detalhesPagamento[pedidoUid];
  }
}

// PedidoController modificado para testes
class PedidoController {
  MockPedidoFirebase? _mockFirebase;

  PedidoController.paraTestar(MockPedidoFirebase mockFirebase) {
    _mockFirebase = mockFirebase;
  }

  PedidoController();

  MockPedidoFirebase get pedidoFirebase => _mockFirebase!;

  Future<void> cadastrarPedido(Pedido pedido) async {
    try {
      String? uid = pedidoFirebase.pegarIdUsuarioLogado();

      if (uid == null) {
        throw Exception('Usuário não logado');
      }

      String? gerenteUid = await pedidoFirebase.pegarGerenteUid(uid);

      if (gerenteUid == null) {
        throw Exception('GerenteUid não encontrado para o usuário');
      }

      pedido.gerenteUid = gerenteUid;
      await pedidoFirebase.adicionarPedido(pedido);
    } catch (e) {
      throw Exception('Erro ao cadastrar pedido: ${e.toString()}');
    }
  }

  Future<void> atualizarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await pedidoFirebase.atualizarStatus(pedidoId, novoStatus);
    } catch (e) {
      throw Exception('Erro ao atualizar status do pedido: ${e.toString()}');
    }
  }

  Future<Stream<List<Pedido>>> listarPedidosTempoReal() async {
    final uid = pedidoFirebase.pegarIdUsuarioLogado();
    if (uid == null) {
      throw Exception("Usuário não logado");
    }

    final gerenteUid = await pedidoFirebase.pegarGerenteUid(uid);

    if (gerenteUid == null) {
      throw Exception("GerenteUid não encontrado");
    }

    return pedidoFirebase.ouvirPedidosTempoReal(gerenteUid);
  }

  Future<bool> processarPagamento({
    required String pedidoUid,
    required String metodoPagamento,
    required double valorPago,
    double desconto = 0.0,
    double? troco,
  }) async {
    try {
      if (pedidoUid.isEmpty) {
        throw Exception('UID do pedido é obrigatório');
      }

      final pedido = await buscarPedidoPorUid(pedidoUid);

      if (pedido == null) {
        throw Exception('Pedido não encontrado');
      }

      if (pedido.pago) {
        throw Exception('Este pedido já foi pago');
      }

      final totalComDesconto = pedido.calcularTotal() - desconto;
      if (metodoPagamento == 'Dinheiro' && valorPago < totalComDesconto) {
        throw Exception('Valor pago insuficiente');
      }

      await pedidoFirebase.marcarComoPago(
        pedidoUid: pedidoUid,
        metodoPagamento: metodoPagamento,
        valorPago: valorPago,
        desconto: desconto,
        troco: troco ?? 0.0,
      );

      await pedidoFirebase.atualizarStatus(pedidoUid, 'Entregue');

      return true;
    } catch (e) {
      print("Erro no processamento de pagamento: $e");
      return false;
    }
  }

  Future<Pedido?> buscarPedidoPorUid(String uid) async {
    try {
      final pedido = await pedidoFirebase.buscarPedidoPorUid(uid);

      if (pedido == null) {
        throw Exception('Erro ao buscar');
      }

      return pedido;
    } catch (e) {
      return null;
    }
  }

  Future<String> confirmarSenhaCancelar(Pedido pedido, String senha) async {
    final uid = pedidoFirebase.pegarIdUsuarioLogado();
    final gerenteUid = await pedidoFirebase.pegarGerenteUid(uid!);

    final res = await pedidoFirebase.verificarSenhaGerente(gerenteUid!, senha);

    if (res) {
      await excluirPedido(pedido);
      return 'Pedido Cancelado';
    } else {
      return 'Senha incorreta. O pedido não foi cancelado.';
    }
  }

  Future<bool> editarPedido(Pedido pedido) async {
    if (pedido.statusAtual != "Aberto") {
      throw Exception("Só é possível editar pedidos com status 'Aberto'.");
    }

    if (pedido.uid == null) {
      throw Exception("Pedido inválido para edição.");
    }

    try {
      if (pedido.gerenteUid == null) {
        final uid = pedidoFirebase.pegarIdUsuarioLogado();
        if (uid == null) throw Exception("Usuário não logado");

        final gerenteUid = await pedidoFirebase.pegarGerenteUid(uid);

        if (gerenteUid == null) {
          throw Exception("GerenteUid não encontrado para o usuário");
        }

        pedido.gerenteUid = gerenteUid;
      }

      await pedidoFirebase.editarPedido(pedido.uid!, pedido.toMap());
      return true;
    } catch (e) {
      print("Erro ao editar pedido: $e");
      return false;
    }
  }

  Future<bool> excluirPedido(Pedido pedido) async {
    if (pedido.uid == null) {
      throw Exception("Pedido inválido para exclusão.");
    }

    try {
      await pedidoFirebase.excluirPedido(pedido.uid!);
      return true;
    } catch (e) {
      print("Erro ao excluir pedido: $e");
      return false;
    }
  }

  Future<bool> mudarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await pedidoFirebase.atualizarStatus(pedidoId, novoStatus);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> gerarRelatorioDoDia() async {
    final hoje = DateTime.now();
    final pedidos = await pedidoFirebase.buscarPedidosDoDia(hoje);

    double totalVendas = 0.0;
    int qtdPedidos = pedidos.length;
    Map<String, int> statusCount = {};
    Map<String, double> pagamentoPorMetodo = {
      'Dinheiro': 0,
      'Cartão': 0,
      'PIX': 0,
    };

    for (var pedido in pedidos) {
      totalVendas += pedido.calcularTotal();

      statusCount[pedido.statusAtual] = (statusCount[pedido.statusAtual] ?? 0) + 1;

      if (pedido.pago) {
        final detalhe = await pedidoFirebase.buscarDetalhePagamento(pedido.uid!);
        if (detalhe != null) {
          final metodo = detalhe['metodoPagamento'] ?? 'Outro';
          pagamentoPorMetodo[metodo] = (pagamentoPorMetodo[metodo] ?? 0) + pedido.calcularTotal();
        }
      }
    }

    return {
      'totalVendas': totalVendas,
      'qtdPedidos': qtdPedidos,
      'statusCount': statusCount,
      'pagamentoPorMetodo': pagamentoPorMetodo,
    };
  }

  Future<Map<String, dynamic>> gerarRelatorio({bool semanal = false}) async {
    final agora = DateTime.now();
    DateTime inicio;
    DateTime fim;

    if (semanal) {
      final inicioDia = DateTime(agora.year, agora.month, agora.day);
      inicio = inicioDia.subtract(Duration(days: 6));
      fim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);
    } else {
      inicio = DateTime(agora.year, agora.month, agora.day, 0, 0, 0);
      fim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);
    }

    final pedidos = await pedidoFirebase.buscarPedidosPorPeriodo(inicio, fim);

    double totalVendas = 0.0;
    int qtdPedidos = pedidos.length;
    Map<String, int> statusCount = {};
    Map<String, double> pagamentoPorMetodo = {
      "Dinheiro": 0.0,
      "Cartão": 0.0,
      "PIX": 0.0,
      "Outro": 0.0,
    };

    for (var pedido in pedidos) {
      if (pedido.uid != null) {
        final detalhe = await pedidoFirebase.buscarDetalhePagamento(pedido.uid!);

        if (detalhe != null) {
          final valor = (detalhe['valorPago'] as num).toDouble();
          final metodo = detalhe['metodoPagamento'] as String? ?? 'Outro';

          totalVendas += valor;
          pagamentoPorMetodo[metodo] = (pagamentoPorMetodo[metodo] ?? 0.0) + valor;
        }
      }

      statusCount[pedido.statusAtual] = (statusCount[pedido.statusAtual] ?? 0) + 1;
    }

    return {
      'totalVendas': totalVendas,
      'qtdPedidos': qtdPedidos,
      'statusCount': statusCount,
      'pagamentoPorMetodo': pagamentoPorMetodo,
      'periodoInicio': inicio,
      'periodoFim': fim,
    };
  }
}

void main() {
  group('PedidoController Tests', () {
    late PedidoController controller;
    late MockPedidoFirebase mockPedidoFirebase;

    setUp(() {
      mockPedidoFirebase = MockPedidoFirebase();
      controller = PedidoController.paraTestar(mockPedidoFirebase);
    });

    tearDown(() {
      mockPedidoFirebase.reset();
    });

    group('cadastrarPedido', () {
      test('deve cadastrar pedido com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [
          ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 2),
        ];
        final pedido = Pedido(
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setUsuarioLogado('usuario123');
        mockPedidoFirebase.setGerenteUid('gerente123');

        // Act
        await controller.cadastrarPedido(pedido);

        // Assert
        expect(mockPedidoFirebase.chamadas, contains('pegarIdUsuarioLogado'));
        expect(mockPedidoFirebase.chamadas, contains('pegarGerenteUid:usuario123'));
        expect(mockPedidoFirebase.chamadas, contains('adicionarPedido'));
        expect(pedido.gerenteUid, 'gerente123');
      });

      test('deve lançar exceção quando usuário não está logado', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.cadastrarPedido(pedido),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando gerenteUid não é encontrado', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setUsuarioLogado('usuario123');
        mockPedidoFirebase.setGerenteUid(null);

        // Act & Assert
        expect(
              () => controller.cadastrarPedido(pedido),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('atualizarStatusPedido', () {
      test('deve atualizar status com sucesso', () async {
        // Arrange
        const pedidoId = 'pedido123';
        const novoStatus = 'Em Preparo';

        // Act
        await controller.atualizarStatusPedido(pedidoId, novoStatus);

        // Assert
        expect(
          mockPedidoFirebase.chamadas,
          contains('atualizarStatus:pedido123:Em Preparo'),
        );
      });

      test('deve lançar exceção quando ocorre erro ao atualizar', () async {
        // Arrange
        mockPedidoFirebase.setDeveGerarErro(true);

        // Act & Assert
        expect(
              () => controller.atualizarStatusPedido('pedido123', 'Pronto'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listarPedidosTempoReal', () {
      test('deve retornar stream de pedidos com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
          gerenteUid: 'gerente123',
        );

        mockPedidoFirebase.setUsuarioLogado('usuario123');
        mockPedidoFirebase.setGerenteUid('gerente123');
        mockPedidoFirebase.setPedido('pedido1', pedido);

        // Act
        final stream = await controller.listarPedidosTempoReal();
        final resultado = await stream.first;

        // Assert
        expect(resultado, hasLength(1));
        expect(resultado.first.uid, 'pedido1');
        expect(mockPedidoFirebase.chamadas, contains('ouvirPedidosTempoReal:gerente123'));
      });

      test('deve lançar exceção quando usuário não está logado', () async {
        // Arrange
        mockPedidoFirebase.setUsuarioLogado(null);

        // Act & Assert
        expect(
              () => controller.listarPedidosTempoReal(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('processarPagamento', () {
      test('deve processar pagamento com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 2)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Pronto',
          pago: false,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido);

        // Act
        final resultado = await controller.processarPagamento(
          pedidoUid: 'pedido1',
          metodoPagamento: 'Dinheiro',
          valorPago: 70.0,
          desconto: 5.0,
          troco: 15.0,
        );

        // Assert
        expect(resultado, true);
        expect(mockPedidoFirebase.chamadas, contains('buscarPedidoPorUid:pedido1'));
        expect(mockPedidoFirebase.chamadas, contains('marcarComoPago:pedido1'));
        expect(mockPedidoFirebase.chamadas, contains('atualizarStatus:pedido1:Entregue'));
      });

      test('deve retornar false quando pedido não é encontrado', () async {
        // Arrange
        // Não adiciona nenhum pedido ao mock, então a busca retornará null

        // Act
        final resultado = await controller.processarPagamento(
          pedidoUid: 'pedido999',
          metodoPagamento: 'Dinheiro',
          valorPago: 50.0,
        );

        // Assert
        expect(resultado, false);
      });

      test('deve retornar false quando pedido já está pago', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Entregue',
          pago: true,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido);

        // Act
        final resultado = await controller.processarPagamento(
          pedidoUid: 'pedido1',
          metodoPagamento: 'Cartão',
          valorPago: 30.0,
        );

        // Assert
        expect(resultado, false);
      });

      test('deve retornar false quando valor pago é insuficiente', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 2)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Pronto',
          pago: false,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido);

        // Act
        final resultado = await controller.processarPagamento(
          pedidoUid: 'pedido1',
          metodoPagamento: 'Dinheiro',
          valorPago: 50.0, // Total é 60.0
        );

        // Assert
        expect(resultado, false);
      });

      test('deve lançar exceção quando UID do pedido está vazio', () async {
        // Act
        final resultado = await controller.processarPagamento(
          pedidoUid: '',
          metodoPagamento: 'Cartão',
          valorPago: 50.0,
        );

        // Assert
        expect(resultado, false);
      });
    });

    group('buscarPedidoPorUid', () {
      test('deve buscar pedido com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setPedido('pedido1', pedido);

        // Act
        final resultado = await controller.buscarPedidoPorUid('pedido1');

        // Assert
        expect(resultado, isNotNull);
        expect(resultado!.uid, 'pedido1');
        expect(mockPedidoFirebase.chamadas, contains('buscarPedidoPorUid:pedido1'));
      });

      test('deve retornar null quando pedido não existe', () async {
        // Act
        final resultado = await controller.buscarPedidoPorUid('pedido999');

        // Assert
        expect(resultado, isNull);
      });
    });

    group('confirmarSenhaCancelar', () {
      test('deve cancelar pedido quando senha está correta', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setUsuarioLogado('usuario123');
        mockPedidoFirebase.setGerenteUid('gerente123');
        mockPedidoFirebase.setSenhaGerente('gerente123', 'senha123', true);

        // Act
        final resultado = await controller.confirmarSenhaCancelar(pedido, 'senha123');

        // Assert
        expect(resultado, 'Pedido Cancelado');
        expect(mockPedidoFirebase.chamadas, contains('verificarSenhaGerente:gerente123'));
        expect(mockPedidoFirebase.chamadas, contains('excluirPedido:pedido1'));
      });

      test('deve retornar erro quando senha está incorreta', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setUsuarioLogado('usuario123');
        mockPedidoFirebase.setGerenteUid('gerente123');
        mockPedidoFirebase.setSenhaGerente('gerente123', 'senha123', false);

        // Act
        final resultado = await controller.confirmarSenhaCancelar(pedido, 'senhaerrada');

        // Assert
        expect(resultado, 'Senha incorreta. O pedido não foi cancelado.');
      });
    });

    group('editarPedido', () {
      test('deve editar pedido com status Aberto com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
          gerenteUid: 'gerente123',
        );

        // Act
        final resultado = await controller.editarPedido(pedido);

        // Assert
        expect(resultado, true);
        expect(mockPedidoFirebase.chamadas, contains('editarPedido:pedido1'));
      });

      test('deve lançar exceção quando pedido não está com status Aberto', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Em Preparo',
        );

        // Act & Assert
        expect(
              () => controller.editarPedido(pedido),
          throwsA(isA<Exception>()),
        );
      });

      test('deve lançar exceção quando UID do pedido é nulo', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        // Act & Assert
        expect(
              () => controller.editarPedido(pedido),
          throwsA(isA<Exception>()),
        );
      });

      test('deve buscar gerenteUid quando não está definido no pedido', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setUsuarioLogado('usuario123');
        mockPedidoFirebase.setGerenteUid('gerente123');

        // Act
        final resultado = await controller.editarPedido(pedido);

        // Assert
        expect(resultado, true);
        expect(pedido.gerenteUid, 'gerente123');
        expect(mockPedidoFirebase.chamadas, contains('pegarGerenteUid:usuario123'));
      });
    });

    group('excluirPedido', () {
      test('deve excluir pedido com sucesso', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        // Act
        final resultado = await controller.excluirPedido(pedido);

        // Assert
        expect(resultado, true);
        expect(mockPedidoFirebase.chamadas, contains('excluirPedido:pedido1'));
      });

      test('deve lançar exceção quando UID do pedido é nulo', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        // Act & Assert
        expect(
              () => controller.excluirPedido(pedido),
          throwsA(isA<Exception>()),
        );
      });

      test('deve retornar false quando ocorre erro ao excluir', () async {
        // Arrange
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
        final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];
        final pedido = Pedido(
          uid: 'pedido1',
          horario: DateTime.now(),
          mesa: mesa,
          itens: itens,
          statusAtual: 'Aberto',
        );

        mockPedidoFirebase.setDeveGerarErro(true);

        // Act
        final resultado = await controller.excluirPedido(pedido);

        // Assert
        expect(resultado, false);
      });
    });

    group('mudarStatusPedido', () {
      test('deve mudar status com sucesso', () async {
        // Act
        final resultado = await controller.mudarStatusPedido('pedido1', 'Pronto');

        // Assert
        expect(resultado, true);
        expect(mockPedidoFirebase.chamadas, contains('atualizarStatus:pedido1:Pronto'));
      });

      test('deve retornar false quando ocorre erro', () async {
        // Arrange
        mockPedidoFirebase.setDeveGerarErro(true);

        // Act
        final resultado = await controller.mudarStatusPedido('pedido1', 'Pronto');

        // Assert
        expect(resultado, false);
      });
    });

    group('gerarRelatorioDoDia', () {
      test('deve gerar relatório do dia com sucesso', () async {
        // Arrange
        final hoje = DateTime.now();
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');

        final pedido1 = Pedido(
          uid: 'pedido1',
          horario: hoje,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 2)],
          statusAtual: 'Entregue',
          pago: true,
        );

        final pedido2 = Pedido(
          uid: 'pedido2',
          horario: hoje,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item2', nome: 'Hambúrguer', preco: 20.0)],
          statusAtual: 'Aberto',
          pago: false,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido1);
        mockPedidoFirebase.setPedido('pedido2', pedido2);
        mockPedidoFirebase.setDetalhePagamento('pedido1', {
          'metodoPagamento': 'Dinheiro',
          'valorPago': 60.0,
        });

        // Act
        final relatorio = await controller.gerarRelatorioDoDia();

        // Assert
        expect(relatorio['totalVendas'], 80.0); // 60 + 20
        expect(relatorio['qtdPedidos'], 2);
        expect(relatorio['statusCount']['Entregue'], 1);
        expect(relatorio['statusCount']['Aberto'], 1);
        expect(relatorio['pagamentoPorMetodo']['Dinheiro'], 60.0);
      });

      test('deve retornar relatório vazio quando não há pedidos', () async {
        // Act
        final relatorio = await controller.gerarRelatorioDoDia();

        // Assert
        expect(relatorio['totalVendas'], 0.0);
        expect(relatorio['qtdPedidos'], 0);
        expect(relatorio['statusCount'], isEmpty);
      });
    });

    group('gerarRelatorio', () {
      test('deve gerar relatório diário com sucesso', () async {
        // Arrange
        final hoje = DateTime.now();
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');

        final pedido1 = Pedido(
          uid: 'pedido1',
          horario: hoje,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 50.0)],
          statusAtual: 'Entregue',
          pago: true,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido1);
        mockPedidoFirebase.setDetalhePagamento('pedido1', {
          'metodoPagamento': 'PIX',
          'valorPago': 50.0,
        });

        // Act
        final relatorio = await controller.gerarRelatorio(semanal: false);

        // Assert
        expect(relatorio['totalVendas'], 50.0);
        expect(relatorio['qtdPedidos'], 1);
        expect(relatorio['pagamentoPorMetodo']['PIX'], 50.0);
        expect(relatorio['periodoInicio'], isNotNull);
        expect(relatorio['periodoFim'], isNotNull);
      });

      test('deve gerar relatório semanal com sucesso', () async {
        // Arrange
        final hoje = DateTime.now();
        final ontem = hoje.subtract(Duration(days: 1));
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');

        final pedido1 = Pedido(
          uid: 'pedido1',
          horario: hoje,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)],
          statusAtual: 'Entregue',
          pago: true,
        );

        final pedido2 = Pedido(
          uid: 'pedido2',
          horario: ontem,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item2', nome: 'Hambúrguer', preco: 25.0)],
          statusAtual: 'Entregue',
          pago: true,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido1);
        mockPedidoFirebase.setPedido('pedido2', pedido2);
        mockPedidoFirebase.setDetalhePagamento('pedido1', {
          'metodoPagamento': 'Cartão',
          'valorPago': 30.0,
        });
        mockPedidoFirebase.setDetalhePagamento('pedido2', {
          'metodoPagamento': 'Dinheiro',
          'valorPago': 25.0,
        });

        // Act
        final relatorio = await controller.gerarRelatorio(semanal: true);

        // Assert
        expect(relatorio['totalVendas'], 55.0);
        expect(relatorio['qtdPedidos'], 2);
        expect(relatorio['pagamentoPorMetodo']['Cartão'], 30.0);
        expect(relatorio['pagamentoPorMetodo']['Dinheiro'], 25.0);
      });

      test('deve agrupar múltiplos pagamentos por método corretamente', () async {
        // Arrange
        final hoje = DateTime.now();
        final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');

        final pedido1 = Pedido(
          uid: 'pedido1',
          horario: hoje,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)],
          statusAtual: 'Entregue',
          pago: true,
        );

        final pedido2 = Pedido(
          uid: 'pedido2',
          horario: hoje,
          mesa: mesa,
          itens: [ItemCardapio(uid: 'item2', nome: 'Pizza 2', preco: 40.0)],
          statusAtual: 'Entregue',
          pago: true,
        );

        mockPedidoFirebase.setPedido('pedido1', pedido1);
        mockPedidoFirebase.setPedido('pedido2', pedido2);
        mockPedidoFirebase.setDetalhePagamento('pedido1', {
          'metodoPagamento': 'Dinheiro',
          'valorPago': 30.0,
        });
        mockPedidoFirebase.setDetalhePagamento('pedido2', {
          'metodoPagamento': 'Dinheiro',
          'valorPago': 40.0,
        });

        // Act
        final relatorio = await controller.gerarRelatorio(semanal: false);

        // Assert
        expect(relatorio['pagamentoPorMetodo']['Dinheiro'], 70.0);
      });
    });
  });

  group('Testes de Validação de Pedido', () {
    test('deve criar um pedido válido', () {
      // Arrange
      final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
      final itens = [
        ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 2),
      ];
      final horario = DateTime.now();

      // Act
      final pedido = Pedido(
        horario: horario,
        mesa: mesa,
        itens: itens,
        statusAtual: 'Aberto',
      );

      // Assert
      expect(pedido.horario, horario);
      expect(pedido.mesa.numero, 1);
      expect(pedido.itens, hasLength(1));
      expect(pedido.statusAtual, 'Aberto');
      expect(pedido.pago, false);
    });

    test('deve calcular total do pedido corretamente', () {
      // Arrange
      final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
      final itens = [
        ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 2),
        ItemCardapio(uid: 'item2', nome: 'Refrigerante', preco: 5.0, quantidade: 3),
      ];

      final pedido = Pedido(
        horario: DateTime.now(),
        mesa: mesa,
        itens: itens,
        statusAtual: 'Aberto',
      );

      // Act
      final total = pedido.calcularTotal();

      // Assert
      expect(total, 75.0); // (30 * 2) + (5 * 3) = 60 + 15 = 75
    });

    test('deve converter pedido para Map corretamente', () {
      // Arrange
      final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
      final itens = [
        ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0, quantidade: 1),
      ];
      final horario = DateTime.now();

      final pedido = Pedido(
        uid: 'pedido123',
        horario: horario,
        mesa: mesa,
        itens: itens,
        statusAtual: 'Aberto',
        observacao: 'Sem cebola',
        gerenteUid: 'gerente123',
        pago: false,
      );

      // Act
      final map = pedido.toMap();

      // Assert
      expect(map['uid'], 'pedido123');
      expect(map['statusAtual'], 'Aberto');
      expect(map['observacao'], 'Sem cebola');
      expect(map['gerenteUid'], 'gerente123');
      expect(map['pago'], false);
      expect(map['mesa'], isA<Map<String, dynamic>>());
      expect(map['itens'], isA<List>());
    });

    test('deve criar pedido a partir de Map corretamente', () {
      // Arrange
      final horario = DateTime.now();
      final map = {
        'horario': horario.toIso8601String(),
        'mesa': {'uid': 'mesa1', 'numero': 5, 'nome': 'Mesa VIP'},
        'itens': [
          {'uid': 'item1', 'nome': 'Pizza', 'preco': 40.0, 'quantidade': 1, 'observacao': null}
        ],
        'statusAtual': 'Em Preparo',
        'observacao': 'Urgente',
        'gerenteUid': 'gerente456',
        'pago': true,
      };

      // Act
      final pedido = Pedido.fromMap(map, 'pedido789');

      // Assert
      expect(pedido.uid, 'pedido789');
      expect(pedido.mesa.numero, 5);
      expect(pedido.itens, hasLength(1));
      expect(pedido.itens.first.nome, 'Pizza');
      expect(pedido.statusAtual, 'Em Preparo');
      expect(pedido.observacao, 'Urgente');
      expect(pedido.gerenteUid, 'gerente456');
      expect(pedido.pago, true);
    });

    test('deve usar valores padrão quando campos estão ausentes no Map', () {
      // Arrange
      final horario = DateTime.now();
      final map = {
        'horario': horario.toIso8601String(),
        'mesa': {'uid': 'mesa1', 'numero': 1},
        'itens': [],
      };

      // Act
      final pedido = Pedido.fromMap(map, 'pedido999');

      // Assert
      expect(pedido.statusAtual, 'Aberto');
      expect(pedido.observacao, '');
      expect(pedido.pago, false);
    });

    test('deve copiar pedido com novos valores usando copyWith', () {
      // Arrange
      final mesa = Mesa(uid: 'mesa1', numero: 1, nome: 'Mesa 1');
      final itens = [ItemCardapio(uid: 'item1', nome: 'Pizza', preco: 30.0)];

      final pedidoOriginal = Pedido(
        uid: 'pedido1',
        horario: DateTime.now(),
        mesa: mesa,
        itens: itens,
        statusAtual: 'Aberto',
        pago: false,
      );

      // Act
      final pedidoCopia = pedidoOriginal.copyWith(
        statusAtual: 'Entregue',
        pago: true,
      );

      // Assert
      expect(pedidoCopia.uid, 'pedido1');
      expect(pedidoCopia.statusAtual, 'Entregue');
      expect(pedidoCopia.pago, true);

      // Verifica que o original não foi alterado
      expect(pedidoOriginal.statusAtual, 'Aberto');
      expect(pedidoOriginal.pago, false);
    });

    test('deve validar lista de status possíveis', () {
      // Assert
      expect(Pedido.statusOpcoes, contains('Aberto'));
      expect(Pedido.statusOpcoes, contains('Em Preparo'));
      expect(Pedido.statusOpcoes, contains('Pronto'));
      expect(Pedido.statusOpcoes, contains('Entregue'));
      expect(Pedido.statusOpcoes, contains('Cancelado'));
      expect(Pedido.statusOpcoes, hasLength(5));
    });
  });
}