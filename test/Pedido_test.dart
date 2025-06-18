import 'package:floworder/models/ItemCardapio.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:test/test.dart';

void main() {
  group('Pedido', () {
    late Pedido pedido;

    setUp(() {
      pedido = Pedido()
        ..statusAtual = 'Aberto';
    });

    test('deve conter status válidos definidos', () {
      expect(Pedido.status, containsAll(['Aberto', 'Em Preparo', 'Pronto']));
    });

    test('deve definir horário corretamente', () {
      final agora = DateTime.now();
      pedido.horario = agora;
      expect(pedido.horario, equals(agora));
    });

    test('status inicial deve ser Aberto', () {
      expect(pedido.statusAtual, equals('Aberto'));
    });

    test('deve adicionar itens corretamente e calcular total', () {
      final item1 = ItemCardapio()..preco = 10.0;
      final item2 = ItemCardapio()..preco = 15.5;

      pedido.adicionarItem(item1);
      pedido.adicionarItem(item2);

      expect(pedido.itens.length, equals(2));
      expect(pedido.calcularTotal(), equals(25.5));
    });
  });
}
