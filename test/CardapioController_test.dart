import 'package:floworder/controller/CardapioController.dart';
import 'package:floworder/models/ItemCardapio.dart';
import 'package:test/test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('CardapioController', () {
    late FakeFirebaseFirestore fakeFirestore;
    late CardapioController controller;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      controller = CardapioController(firestore: fakeFirestore);
    });

    test('deve adicionar e buscar item do cardápio', () async {
      final item = ItemCardapio()
        ..nome = 'Pizza'
        ..descricao = 'Pizza de mussarela'
        ..preco = 45.0;

      await controller.adicionarItem(item);

      final itens = await controller.buscarTodosItens();
      expect(itens.length, equals(1));
      expect(itens.first.nome, equals('Pizza'));
      expect(itens.first.descricao, equals('Pizza de mussarela'));
      expect(itens.first.preco, equals(45.0));
    });
  });
}
