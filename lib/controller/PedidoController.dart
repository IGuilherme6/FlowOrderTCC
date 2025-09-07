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

  // Métodos para adicionar ao PedidoController

  /// Processa o pagamento de um pedido
  // Versão com debug detalhado do método processarPagamento no PedidoController

  /// Processa o pagamento de um pedido
  Future<bool> processarPagamento({
    required String pedidoUid,
    required String metodoPagamento,
    required double valorPago,
    double desconto = 0.0,
    double? troco,
  }) async {
    try {
      print('🔍 Iniciando processamento de pagamento...');
      print('📋 PedidoUID: $pedidoUid');
      print('💳 Método: $metodoPagamento');
      print('💰 Valor Pago: $valorPago');
      print('🏷️ Desconto: $desconto');

      // 1. Validar se o UID não está vazio
      if (pedidoUid.isEmpty) {
        print('❌ Erro: UID do pedido está vazio');
        throw Exception('UID do pedido é obrigatório');
      }

      // 2. Buscar o pedido atual
      print('🔍 Buscando pedido...');
      final pedido = await buscarPedidoPorUid(pedidoUid);

      if (pedido == null) {
        print('❌ Erro: Pedido não encontrado com UID: $pedidoUid');

        // Debug adicional: vamos listar todos os pedidos para ver se existe
        print('🔍 Listando todos os pedidos para debug...');
        final todosPedidos = await _pedidoFirebase.buscarPedidos();
        print('📊 Total de pedidos encontrados: ${todosPedidos.length}');

        for (final p in todosPedidos) {
          print('📄 Pedido: ${p.uid} - Mesa: ${p.mesa.numero} - Total: ${p.calcularTotal()}');
        }

        throw Exception('Pedido não encontrado');
      }

      print('✅ Pedido encontrado!');
      print('🏠 Mesa: ${pedido.mesa.numero}');
      print('📊 Total original: ${pedido.calcularTotal()}');
      print('📋 Status atual: ${pedido.statusAtual}');
      print('💳 Já pago: ${pedido.pago}');

      // 3. Verificar se já foi pago
      if (pedido.pago) {
        print('⚠️ Aviso: Pedido já foi pago anteriormente');
        throw Exception('Este pedido já foi pago');
      }

      // 4. Validar o pagamento
      final totalComDesconto = pedido.calcularTotal() - desconto;
      print('💰 Total com desconto: $totalComDesconto');

      if (metodoPagamento == 'Dinheiro' && valorPago < totalComDesconto) {
        print('❌ Erro: Valor pago insuficiente');
        print('💰 Necessário: $totalComDesconto, Pago: $valorPago');
        throw Exception('Valor pago insuficiente');
      }

      print('✅ Validações passaram, processando pagamento...');

      // 5. Registrar o pagamento no Firebase
      await _pedidoFirebase.marcarComoPago(
        pedidoUid: pedidoUid,
        metodoPagamento: metodoPagamento,
        valorPago: valorPago,
        desconto: desconto,
        troco: troco ?? 0.0,
      );

      print('✅ Pagamento registrado no Firebase');

      // 6. Atualizar o status se necessário
      if (pedido.statusAtual == 'Aberto') {
        print('📝 Atualizando status para "Em Preparo"...');
        await _pedidoFirebase.atualizarStatus(pedidoUid, 'Em Preparo');
      }

      print('🎉 Pagamento processado com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro ao processar pagamento: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      return false;
    }
  }

// Também vamos melhorar o método buscarPedidoPorUid com mais logs
  Future<Pedido?> buscarPedidoPorUid(String uid) async {
    try {
      print('🔍 Buscando pedido com UID: $uid');

      final pedido = await _pedidoFirebase.buscarPedidoPorUid(uid);

      if (pedido == null) {
        print('❌ Pedido não encontrado no Firebase');
      } else {
        print('✅ Pedido encontrado - Mesa: ${pedido.mesa.numero}');
      }

      return pedido;
    } catch (e) {
      print('❌ Erro ao buscar pedido por UID: $e');
      return null;
    }
  }


}
