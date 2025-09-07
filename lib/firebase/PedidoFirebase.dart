import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import '../models/Pedido.dart';

class PedidoFirebase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _pedidosRef => _firestore.collection('Pedidos');

  UsuarioFirebase user = UsuarioFirebase();

  /// Adiciona um pedido no Firestore
  Future<String> adicionarPedido(Pedido pedido) async {
    try {
      DocumentReference docRef = await _pedidosRef.add(pedido.toMap());
      await docRef.update({'uid': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar pedido: $e');
    }
  }

  /// Atualiza o status de um pedido
  Future<void> atualizarStatus(String pedidoId, String novoStatus) async {
    try {
      await _pedidosRef.doc(pedidoId).update({'statusAtual': novoStatus});
    } catch (e) {
      throw Exception('Erro ao atualizar status do pedido: $e');
    }
  }

  /// Exclui um pedido
  Future<void> excluirPedido(String pedidoId) async {
    try {
      await _pedidosRef.doc(pedidoId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir pedido: $e');
    }
  }

  /// Busca todos os pedidos de uma vez (sem tempo real)
  Future<List<Pedido>> buscarPedidos() async {
    try {
      QuerySnapshot snapshot = await _pedidosRef.get();
      return snapshot.docs
          .map(
            (doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id),
      )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar pedidos: $e');
    }
  }

  /// Ouve pedidos em tempo real
  Stream<List<Pedido>> ouvirPedidosTempoReal(String gerenteUid) {
    return _firestore
        .collection('Pedidos')
        .where('gerenteUid', isEqualTo: gerenteUid)
        .where('pago', isEqualTo: false)
        .orderBy('horario', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Pedido.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Marca um pedido como pago e registra informações do pagamento
  Future<void> marcarComoPago({
    required String pedidoUid,
    required String metodoPagamento,
    required double valorPago,
    required double desconto,
    required double troco,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Atualizar o pedido marcando como pago
      final pedidoRef = _pedidosRef.doc(pedidoUid);
      batch.update(pedidoRef, {
        'pago': true,
        'dataPagamento': FieldValue.serverTimestamp(),
      });

      // 2. Criar registro detalhado do pagamento em uma subcoleção
      final pagamentoRef = pedidoRef.collection('pagamentos').doc();
      batch.set(pagamentoRef, {
        'metodoPagamento': metodoPagamento,
        'valorPago': valorPago,
        'desconto': desconto,
        'troco': troco,
        'dataPagamento': FieldValue.serverTimestamp(),
        'processadoPor': 'sistema', // Você pode passar o UID do usuário logado
      });

      await batch.commit();
      print('Pagamento registrado com sucesso para pedido: $pedidoUid');
    } catch (e) {
      print('Erro ao marcar pedido como pago: $e');
      throw Exception('Falha ao processar pagamento');
    }
  }

  /// Busca um pedido específico por UID
  Future<Pedido?> buscarPedidoPorUid(String uid) async {
    try {
      final doc = await _pedidosRef.doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Pedido.fromMap(data, doc.id);
    } catch (e) {
      print('Erro ao buscar pedido por UID: $e');
      return null;
    }
  }

  /// Estorna um pagamento (marca como não pago)
  Future<void> estornarPagamento(String pedidoUid) async {
    try {
      final batch = _firestore.batch();

      // 1. Atualizar o pedido removendo o status de pago
      final pedidoRef = _pedidosRef.doc(pedidoUid);
      batch.update(pedidoRef, {
        'pago': false,
        'dataPagamento': FieldValue.delete(),
      });

      // 2. Adicionar registro de estorno na subcoleção de pagamentos
      final estornoRef = pedidoRef.collection('pagamentos').doc();
      batch.set(estornoRef, {
        'tipo': 'estorno',
        'dataEstorno': FieldValue.serverTimestamp(),
        'processadoPor': 'sistema', // Você pode passar o UID do usuário logado
        'motivo': 'Estorno manual',
      });

      await batch.commit();
      print('Estorno processado com sucesso para pedido: $pedidoUid');
    } catch (e) {
      print('Erro ao estornar pagamento: $e');
      throw Exception('Falha ao processar estorno');
    }
  }

  /// Busca pedidos pagos em um período específico
  Future<List<Pedido>> buscarPedidosPagos({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Query query = _pedidosRef.where('pago', isEqualTo: true);

      // Aplicar filtros de data se fornecidos
      if (dataInicio != null) {
        query = query.where('dataPagamento',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicio));
      }

      if (dataFim != null) {
        // Adicionar um dia ao fim para incluir todo o dia final
        final dataFimFinal = dataFim.add(const Duration(days: 1));
        query = query.where('dataPagamento',
            isLessThan: Timestamp.fromDate(dataFimFinal));
      }

      // Ordenar por data de pagamento
      query = query.orderBy('dataPagamento', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Pedido.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar pedidos pagos: $e');
      return [];
    }
  }

  /// Busca informações detalhadas de pagamento de um pedido
  Future<Map<String, dynamic>?> buscarDetalhePagamento(String pedidoUid) async {
    try {
      final pagamentosSnapshot = await _pedidosRef
          .doc(pedidoUid)
          .collection('pagamentos')
          .where('tipo', isNotEqualTo: 'estorno')
          .orderBy('dataPagamento', descending: true)
          .limit(1)
          .get();

      if (pagamentosSnapshot.docs.isEmpty) {
        return null;
      }

      final doc = pagamentosSnapshot.docs.first;
      final data = doc.data();

      return {
        'uid': doc.id,
        'metodoPagamento': data['metodoPagamento'],
        'valorPago': data['valorPago'],
        'desconto': data['desconto'] ?? 0.0,
        'troco': data['troco'] ?? 0.0,
        'dataPagamento': (data['dataPagamento'] as Timestamp).toDate(),
        'processadoPor': data['processadoPor'],
      };
    } catch (e) {
      print('Erro ao buscar detalhe do pagamento: $e');
      return null;
    }
  }

  /// Busca relatório de vendas por método de pagamento
  Future<Map<String, dynamic>> buscarRelatorioMetodosPagamento({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      // Buscar todos os pedidos pagos no período
      final pedidosPagos = await buscarPedidosPagos(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      Map<String, double> totalPorMetodo = {
        'Dinheiro': 0.0,
        'Cartão': 0.0,
        'PIX': 0.0,
      };

      Map<String, int> quantidadePorMetodo = {
        'Dinheiro': 0,
        'Cartão': 0,
        'PIX': 0,
      };

      // Para cada pedido pago, buscar o método de pagamento
      for (final pedido in pedidosPagos) {
        final detalhePagamento = await buscarDetalhePagamento(pedido.uid!);

        if (detalhePagamento != null) {
          final metodo = detalhePagamento['metodoPagamento'] as String;
          final valor = pedido.calcularTotal();

          totalPorMetodo[metodo] = (totalPorMetodo[metodo] ?? 0.0) + valor;
          quantidadePorMetodo[metodo] = (quantidadePorMetodo[metodo] ?? 0) + 1;
        }
      }

      return {
        'totalPorMetodo': totalPorMetodo,
        'quantidadePorMetodo': quantidadePorMetodo,
        'periodoInicio': dataInicio,
        'periodoFim': dataFim,
      };
    } catch (e) {
      print('Erro ao buscar relatório de métodos de pagamento: $e');
      return {
        'totalPorMetodo': {'Dinheiro': 0.0, 'Cartão': 0.0, 'PIX': 0.0},
        'quantidadePorMetodo': {'Dinheiro': 0, 'Cartão': 0, 'PIX': 0},
      };
    }
  }

  Future<void> editarPedido(String uid, Map<String, dynamic> dadosAtualizados) async {
    await _pedidosRef.doc(uid).update(dadosAtualizados);
  }

}