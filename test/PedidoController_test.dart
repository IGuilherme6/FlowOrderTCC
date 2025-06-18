import 'package:floworder/controller/PedidoController.dart';
import 'package:floworder/models/ItemCardapio.dart';
import 'package:floworder/models/Mesa.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:test/test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';


void main() {
  group('PedidoController', () {
    late FakeFirebaseFirestore fakeFirestore;
    late PedidoController controller;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      controller = PedidoController(firestore: fakeFirestore);
    });

    test('deve cadastrar pedido corretamente', () async {
      final pedido = Pedido()
        ..horario = DateTime.now()
        ..mesa = (Mesa()..numero = 1)
        ..itens = [ItemCardapio()..nome = 'Suco'];

      await controller.cadastrarPedido(pedido);

      final snapshot = await fakeFirestore.collection('pedidos').get();
      expect(snapshot.docs.length, equals(1));
      expect(snapshot.docs.first.data()['mesa'], equals(1));
      expect(snapshot.docs.first.data()['itens'], contains('Suco'));
      expect(snapshot.docs.first.data()['status'], contains('Aberto'));
    });
  });
}
