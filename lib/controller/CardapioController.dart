import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ItemCardapio.dart';

class CardapioController {
  final FirebaseFirestore _firestore;
  final CollectionReference _cardapioRef;

  CardapioController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _cardapioRef = (firestore ?? FirebaseFirestore.instance).collection('cardapio');

  Future<void> adicionarItem(ItemCardapio item) async {
    await _cardapioRef.add({
      'nome': item.nome,
      'descricao': item.descricao,
      'preco': item.preco,
    });
  }

  Future<List<ItemCardapio>> buscarTodosItens() async {
    QuerySnapshot querySnapshot = await _cardapioRef.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ItemCardapio()
        ..nome = data['nome']
        ..descricao = data['descricao']
        ..preco = data['preco'];
    }).toList();
  }

  Future<void> atualizarItem(String id, ItemCardapio item) async {
    await _cardapioRef.doc(id).update({
      'nome': item.nome,
      'descricao': item.descricao,
      'preco': item.preco,
    });
  }

  Future<void> removerItem(String id) async {
    await _cardapioRef.doc(id).delete();
  }

  Future<ItemCardapio?> buscarItemPorId(String id) async {
    final doc = await _cardapioRef.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return ItemCardapio()
        ..nome = data['nome']
        ..descricao = data['descricao']
        ..preco = data['preco'];
    }
    return null;
  }
}
