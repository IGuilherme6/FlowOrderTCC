import 'package:floworder/firebase/CardapioFirebase.dart';
import 'package:floworder/firebase/MesaFirebase.dart';
import 'package:floworder/firebase/PedidoFirebase.dart';
import 'package:floworder/models/Pedido.dart';

class RelatorioService {
  final CardapioFirebase _cardapioFirebase = CardapioFirebase();
  final MesaFirebase _mesaFirebase = MesaFirebase();
  final PedidoFirebase _pedidoFirebase = PedidoFirebase();

  /// Gera o relatório conforme tipo escolhido.
  /// Quando inicio/fim informados, busca tanto por dataPagamento (pedidos pagos)
  /// quanto por periodo (horario) e une os resultados para evitar "dados misturados".
  Future<Map<String, dynamic>> gerarRelatorio({
    required String gerenteUid,
    required String tipo,
    DateTime? inicio,
    DateTime? fim,
    String status = "todos",
  }) async {
    try {
      // 1) Buscar pedidos (com atenção à data)
      List<Pedido> pedidos = [];

      if (inicio != null && fim != null) {
        // Busca pedidos pagos filtrando por dataPagamento
        final pagos = await _pedidoFirebase.buscarPedidosPagos(
          dataInicio: inicio,
          dataFim: fim,
        );

        // Busca pedidos por período (horario)
        final periodo = await _pedidoFirebase.buscarPedidosPorPeriodo(inicio, fim);

        // Combina por uid (evita duplicatas)
        final mapa = <String, Pedido>{};
        for (var p in pagos) {
          if (p.uid != null) mapa[p.uid!] = p;
        }
        for (var p in periodo) {
          if (p.uid != null) mapa[p.uid!] = p;
        }
        pedidos = mapa.values.toList();
      } else {
        // Sem filtro de data -> buscar todos
        pedidos = await _pedidoFirebase.buscarPedidos();
      }

      // 2) Filtra por gerenteUid (campo no documento)
      pedidos = pedidos.where((p) => p.gerenteUid == gerenteUid).toList();

      // 3) Se for detalhado e tiver filtro de status, aplica
      if (tipo == 'vendas_detalhado' && status != 'todos') {
        pedidos = pedidos.where((p) => p.statusAtual == status).toList();
      }

      // 4) Buscar mesas e montar mapa numero -> nome
      final mesasSnap = await _mesaFirebase.buscarMesas(gerenteUid);
      final mesas = _mesaFirebase.querySnapshotParaMesas(mesasSnap);
      final mapaMesas = {for (var m in mesas) m.numero: m.nome};

      // 5) Enriquecer pedidos (sem alterar model) — apenas retorna mapa com pedido + mesaNome
      final pedidosEnriquecidos = pedidos.map((p) {
        final mesaNumero = p.mesa.numero;
        final mesaNomeFallback = (p.mesa.nome.isNotEmpty) ? p.mesa.nome : "Mesa ${mesaNumero}";
        final mesaNome = mapaMesas[mesaNumero] ?? mesaNomeFallback;
        return {
          'pedido': p,
          'mesaNome': mesaNome,
        };
      }).toList();

      // 6) Montar payload por tipo
      switch (tipo) {
        case 'vendas_geral':
          return _gerarRelatorioGeral(pedidosEnriquecidos);
        case 'pagamentos':
          return await _gerarRelatorioPagamentos(pedidosEnriquecidos);
        case 'produtos':
          return _gerarRelatorioProdutos(pedidosEnriquecidos);
        case 'vendas_detalhado':
        default:
          return {'pedidos': pedidosEnriquecidos};
      }
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  Map<String, dynamic> _gerarRelatorioGeral(List<Map<String, dynamic>> pedidos) {
    double total = 0;
    for (var p in pedidos) {
      total += (p['pedido'] as Pedido).calcularTotal();
    }
    return {
      'pedidos': pedidos,
      'resumo': {
        'totalPedidos': pedidos.length,
        'totalVendas': total,
        'ticketMedio': pedidos.isNotEmpty ? total / pedidos.length : 0.0,
      }
    };
  }

  Future<Map<String, dynamic>> _gerarRelatorioPagamentos(List<Map<String, dynamic>> pedidos) async {
    final resultado = <Map<String, dynamic>>[];
    for (var entry in pedidos) {
      final pedido = entry['pedido'] as Pedido;
      final mesaNome = entry['mesaNome'];
      final pagamento = await _pedidoFirebase.buscarDetalhePagamento(pedido.uid!);
      if (pagamento != null) {
        resultado.add({
          'pedido': pedido,
          'mesaNome': mesaNome,
          'pagamento': pagamento,
        });
      }
    }
    return {'pagamentos': resultado};
  }

  Map<String, dynamic> _gerarRelatorioProdutos(List<Map<String, dynamic>> pedidos) {
    final contador = <String, int>{};
    for (var entry in pedidos) {
      final pedido = entry['pedido'] as Pedido;
      for (var item in pedido.itens) {
        contador[item.nome] = (contador[item.nome] ?? 0) + item.quantidade;
      }
    }
    final lista = contador.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {'produtos': lista};
  }
}
