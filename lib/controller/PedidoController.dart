import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floworder/firebase/PedidoFirebase.dart';
import 'package:floworder/firebase/UsuarioFirebase.dart';
import '../models/ItemCardapio.dart';
import '../models/Pedido.dart';
import '../models/Mesa.dart';

class PedidoController {
  final FirebaseFirestore _firestore;
  late final CollectionReference _pedidosRef;
  final UsuarioFirebase _user = UsuarioFirebase();

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
      //TEM QUE ARRUMAR PARA QUE SALVE CORRETAMENTE PASSANDO PARA O PEDIDOFIREBASE
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
  Future<void> atualizarItensPedido(String pedidoId, List<ItemCardapio> novosItens) async {
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

    return PedidoFirebase().ouvirPedidosTempoReal(gerenteUid);
  }
}