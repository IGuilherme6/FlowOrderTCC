import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/firebase/PedidoFirebase.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import '../models/ItemCardapio.dart';
import '../models/Pedido.dart';

class PedidoController {
  final FirebaseFirestore _firestore;
  late final CollectionReference _pedidosRef;
  final UsuarioFirebase _user = UsuarioFirebase();
  PedidoFirebase _pedidoFirebase = PedidoFirebase();

  PedidoController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _pedidosRef = _firestore.collection('Pedidos');
  }

  /// Cadastra um novo pedido no Firestore
  Future<void> cadastrarPedido(Pedido pedido) async {
    try {
      String? uid = _user.pegarIdUsuarioLogado();

      // Busca o documento do usuário
      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uid)
          .get();
      final gerenteUid = doc.data()?['gerenteUid'] as String?;

      if (gerenteUid == null) {
        throw Exception('GerenteUid não encontrado para o usuário');
      }

      pedido.gerenteUid = gerenteUid;
      DocumentReference docRef = await _pedidosRef.add(pedido.toMap());
      await docRef.update({'uid': docRef.id});
    } catch (e) {
      throw Exception('Erro ao cadastrar pedido: $e');
    }
  }

  /// Atualiza o status de um pedido pelo UID
  Future<void> atualizarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await _pedidosRef.doc(pedidoId).update({'statusAtual': novoStatus});
    } catch (e) {
      throw Exception('Erro ao atualizar status do pedido: $e');
    }
  }

  /// Atualiza os itens de um pedido existente
  Future<void> atualizarItensPedido(
    String pedidoId,
    List<ItemCardapio> novosItens,
  ) async {
    try {
      await _pedidosRef.doc(pedidoId).update({
        'itens': novosItens.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Erro ao atualizar itens do pedido: $e');
    }
  }

  /// Ouve pedidos em tempo real
  Future<Stream<List<Pedido>>> listarPedidosTempoReal() async {
    final uid = _user.pegarIdUsuarioLogado();
    if (uid == null) {
      throw Exception("Usuário não logado");
    }

    final doc = await _firestore.collection('Usuarios').doc(uid).get();
    final gerenteUid = doc.data()?['gerenteUid'] as String?;

    if (gerenteUid == null) {
      throw Exception("GerenteUid não encontrado");
    }

    return _pedidoFirebase.ouvirPedidosTempoReal(gerenteUid);
  }


  /// Processa o pagamento de um pedido
  /// Processa o pagamento de um pedido
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

      // Calcular total com desconto
      final totalComDesconto = pedido.calcularTotal() - desconto;
      if (metodoPagamento == 'Dinheiro' && valorPago < totalComDesconto) {
        throw Exception('Valor pago insuficiente');
      }

      // 1. Registrar pagamento no Firebase
      await _pedidoFirebase.marcarComoPago(
        pedidoUid: pedidoUid,
        metodoPagamento: metodoPagamento,
        valorPago: valorPago,
        desconto: desconto,
        troco: troco ?? 0.0,
      );

      // 2. Atualizar status para ENTREGUE
      await _pedidoFirebase.atualizarStatus(pedidoUid, 'Entregue');

      return true;
    } catch (e) {
      print("Erro no processamento de pagamento: $e");
      return false;
    }
  }

// Também vamos melhorar o método buscarPedidoPorUid com mais logs
  Future<Pedido?> buscarPedidoPorUid(String uid) async {
    try {


      final pedido = await _pedidoFirebase.buscarPedidoPorUid(uid);

      if (pedido == null) {
        throw Exception('Erro ao buscar');
      }

      return pedido;
    } catch (e) {

      return null;
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
      // 🔹 Garante que o gerenteUid nunca vá nulo
      if (pedido.gerenteUid == null) {
        final uid = _user.pegarIdUsuarioLogado();
        if (uid == null) throw Exception("Usuário não logado");

        final doc = await _firestore.collection('Usuarios').doc(uid).get();
        final gerenteUid = doc.data()?['gerenteUid'] as String?;

        if (gerenteUid == null) {
          throw Exception("GerenteUid não encontrado para o usuário");
        }

        pedido.gerenteUid = gerenteUid;
      }

      await _pedidoFirebase.editarPedido(pedido.uid!, pedido.toMap());
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

    if (pedido.statusAtual != "Aberto") {
      throw Exception("Só é possível excluir pedidos com status 'Aberto'.");
    }

    try {
      await _pedidoFirebase.excluirPedido(pedido.uid!);
      return true;
    } catch (e) {
      print("Erro ao excluir pedido: $e");
      return false;
    }
  }

  Future<bool> mudarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await _pedidoFirebase.atualizarStatus(pedidoId, novoStatus);
      return true;
    } catch (e) {
      return false;
    }

  }

  Future<Map<String, dynamic>> gerarRelatorioDoDia() async {
    final hoje = DateTime.now();
    final pedidos = await _pedidoFirebase.buscarPedidosDoDia(hoje);

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

      // Contagem por status
      statusCount[pedido.statusAtual] = (statusCount[pedido.statusAtual] ?? 0) + 1;

      // Agrupamento por pagamento
      if (pedido.pago) {
        final detalhe = await _pedidoFirebase.buscarDetalhePagamento(pedido.uid!);
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
      // Aqui usamos "últimos 7 dias" (inclui hoje).
      // Se preferir usar semana calendário (segunda->domingo), substitua esta lógica.
      final inicioDia = DateTime(agora.year, agora.month, agora.day);
      inicio = inicioDia.subtract(Duration(days: 6)); // 6 dias atrás + hoje = 7 dias
      fim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);
    } else {
      // Hoje 00:00:00 → 23:59:59
      inicio = DateTime(agora.year, agora.month, agora.day, 0, 0, 0);
      fim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);
    }

    // Buscar pedidos no período
    final pedidos = await _pedidoFirebase.buscarPedidosPorPeriodo(inicio, fim);

    double totalVendas = 0.0;
    int qtdPedidos = pedidos.length;
    Map<String, int> statusCount = {};
    Map<String, double> pagamentoPorMetodo = {
      "Dinheiro": 0.0,
      "Cartão": 0.0,
      "PIX": 0.0,
      "Outro": 0.0,
    };

    // Busca detalhes de pagamento em paralelo para todos os pedidos
    final futures = pedidos.map((p) async {
      Map<String, dynamic>? detalhe;
      if (p.uid != null) {
        detalhe = await _pedidoFirebase.buscarDetalhePagamento(p.uid!);
      }
      return {'pedido': p, 'detalhe': detalhe};
    }).toList();

    final results = await Future.wait(futures);

    for (final r in results) {
      final Pedido pedido = r['pedido'] as Pedido;
      final detalhe = r['detalhe'] as Map<String, dynamic>?;

      // Somar total de vendas pelos pagamentos encontrados (se houver)
      if (detalhe != null) {
        final valor = (detalhe['valorPago'] as num).toDouble();
        final metodo = detalhe['metodoPagamento'] as String? ?? 'Outro';

        totalVendas += valor;
        pagamentoPorMetodo[metodo] = (pagamentoPorMetodo[metodo] ?? 0.0) + valor;
      }

      // status count (independente de pagamento)
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
