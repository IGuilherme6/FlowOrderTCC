import 'package:cloud_firestore/cloud_firestore.dart';

class RelatorioController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// guarda os pedidos em cache pra não ficar buscando do Firestore toda hora
  List<Map<String, dynamic>>? _cachedPedidos;
  DateTime? _cacheTimestamp;

  // Cache só vale por 5 minutos
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Função pra limpar o cache manualmente, caso precise atualizar os dados
  void clearCache() {
    _cachedPedidos = null;
    _cacheTimestamp = null;
  }

  // Aqui eu checo se o cache ainda está válido
  bool get _isCacheValid {
    if (_cachedPedidos == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidity;
  }

  ///função busca todos os pedidos, mas só vai no Firestore se o cache estiver velho
  Future<List<Map<String, dynamic>>> _getAllPedidos() async {
    if (_isCacheValid) {
      // Se o cache está ok, retorna ele mesmo
      return _cachedPedidos!;
    }

    try {
      // Caso contrário, busca tudo no Firestore
      var snapshot = await _db
          .collection('pedidos')
          .orderBy('horario', descending: true)
          .get();

      // Transformo os documentos em Map e adiciono o uid de cada um
      _cachedPedidos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();

      _cacheTimestamp = DateTime.now();
      return _cachedPedidos!;
    } catch (e) {
      throw Exception('Erro ao buscar pedidos: $e');
    }
  }

  // Lista pedidos com filtros opcionais (status e limite)
  Future<List<Map<String, dynamic>>> listarPedidos({
    int? limite,
    String? status,
  }) async {
    try {
      Query query = _db.collection('pedidos').orderBy('horario', descending: true);

      // Se passou status, filtra
      if (status != null) {
        query = query.where('statusAtual', isEqualTo: status);
      }

      // Se passou limite, aplica
      if (limite != null) {
        query = query.limit(limite);
      }

      var snapshot = await query.get();

      // Retorna uma lista de Maps com os dados e o uid junto
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) return <String, dynamic>{};
        final dataMap = data as Map<String, dynamic>;
        dataMap['uid'] = doc.id;
        return dataMap;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao listar pedidos: $e');
    }
  }

  //calcula quais produtos foram mais vendidos no total
  Future<Map<String, int>> produtosMaisVendidos({int? limite}) async {
    try {
      final pedidos = await _getAllPedidos();
      Map<String, int> ranking = {};

      // Vou somando a quantidade de cada item
      for (var pedido in pedidos) {
        final itens = pedido['itens'] as List<dynamic>? ?? [];

        for (var item in itens) {
          final nome = item['nome'] ?? 'Desconhecido';
          final quantidade = (item['quantidade'] as num? ?? 0).toInt();

          ranking[nome] = (ranking[nome] ?? 0) + quantidade;
        }
      }

      // Ordeno do mais vendido pro menos vendido
      var sorted = ranking.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (limite != null && limite > 0) {
        sorted = sorted.take(limite).toList();
      }

      return Map.fromEntries(sorted);
    } catch (e) {
      throw Exception('Erro ao calcular produtos mais vendidos: $e');
    }
  }

  // Calcula quanto cada produto faturou (quantidade * preço)
  Future<Map<String, double>> faturamentoPorProduto({int? limite}) async {
    try {
      final pedidos = await _getAllPedidos();
      Map<String, double> faturamento = {};

      for (var pedido in pedidos) {
        final itens = pedido['itens'] as List<dynamic>? ?? [];

        for (var item in itens) {
          final nome = item['nome'] ?? 'Desconhecido';
          final preco = (item['preco'] as num? ?? 0).toDouble();
          final quantidade = (item['quantidade'] as num? ?? 0).toInt();

          faturamento[nome] =
              (faturamento[nome] ?? 0) + (preco * quantidade);
        }
      }

      // Ordena do maior faturamento pro menor
      var sorted = faturamento.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (limite != null && limite > 0) {
        sorted = sorted.take(limite).toList();
      }

      return Map.fromEntries(sorted);
    } catch (e) {
      throw Exception('Erro ao calcular faturamento por produto: $e');
    }
  }

  // Conta quantos pedidos foram feitos por dia
  Future<Map<String, int>> pedidosPorDia({
    DateTime? inicio,
    DateTime? fim,
    bool ordenarPorData = true,
  }) async {
    try {
      List<Map<String, dynamic>> pedidos;

      // Se passou intervalo de datas, filtra
      if (inicio != null || fim != null) {
        pedidos = await pedidosPorPeriodo(
          inicio ?? DateTime(2020),
          fim ?? DateTime.now(),
        );
      } else {
        // Caso contrário, usa tudo
        pedidos = await _getAllPedidos();
      }

      Map<String, int> porDia = {};

      // converte a data pra aquele formato DD/MM/AAAA
      for (var pedido in pedidos) {
        final horario = (pedido['horario'] as Timestamp).toDate();
        final dataStr = _formatarData(horario);

        porDia[dataStr] = (porDia[dataStr] ?? 0) + 1;
      }

      // Ordenar por data se quiser
      if (ordenarPorData) {
        var sorted = porDia.entries.toList()
          ..sort((a, b) => _compararDatas(a.key, b.key));

        return Map.fromEntries(sorted);
      }

      return porDia;
    } catch (e) {
      throw Exception('Erro ao calcular pedidos por dia: $e');
    }
  }

  // Soma o faturamento por dia
  Future<Map<String, double>> faturamentoPorDia({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    try {
      List<Map<String, dynamic>> pedidos;

      // Mesma lógica do pedidosPorDia
      if (inicio != null || fim != null) {
        pedidos = await pedidosPorPeriodo(
          inicio ?? DateTime(2020),
          fim ?? DateTime.now(),
        );
      } else {
        pedidos = await _getAllPedidos();
      }

      Map<String, double> faturamentoDia = {};

      for (var pedido in pedidos) {
        final itens = pedido['itens'] as List<dynamic>? ?? [];
        final horario = (pedido['horario'] as Timestamp).toDate();
        final dataStr = _formatarData(horario);

        double total = 0.0;

        // Calcula o total do pedido
        for (var item in itens) {
          final preco = (item['preco'] as num? ?? 0).toDouble();
          final quantidade = (item['quantidade'] as num? ?? 0).toInt();
          total += preco * quantidade;
        }

        faturamentoDia[dataStr] = (faturamentoDia[dataStr] ?? 0) + total;
      }

      // Ordena por data
      var sorted = faturamentoDia.entries.toList()
        ..sort((a, b) => _compararDatas(a.key, b.key));

      return Map.fromEntries(sorted);
    } catch (e) {
      throw Exception('Erro ao calcular faturamento por dia: $e');
    }
  }

  //busca pedidos entre duas datas
  Future<List<Map<String, dynamic>>> pedidosPorPeriodo(DateTime inicio, DateTime fim) async {
    try {
      DateTime inicioAjustado = DateTime(inicio.year, inicio.month, inicio.day);
      DateTime fimAjustado = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);

      var snapshot = await _db
          .collection('pedidos')
          .where('horario', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioAjustado))
          .where('horario', isLessThanOrEqualTo: Timestamp.fromDate(fimAjustado))
          .orderBy('horario', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar pedidos por período: $e');
    }
  }

  //  faz um resumo geral dos pedidos: total, ticket médio, produto mais vendido, etc.
  Future<Map<String, dynamic>> estatisticasGerais({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    try {
      final pedidos = await pedidosPorPeriodo(
        inicio ?? DateTime(2020),
        fim ?? DateTime.now(),
      );

      if (pedidos.isEmpty) {
        return {
          'totalPedidos': 0,
          'faturamentoTotal': 0.0,
          'ticketMedio': 0.0,
          'produtoMaisVendido': 'N/A',
          'diaMaisMovimentado': 'N/A',
        };
      }

      double totalFaturamento = 0.0;

      // Soma geral de tudo
      for (var pedido in pedidos) {
        final itens = pedido['itens'] as List<dynamic>? ?? [];
        for (var item in itens) {
          final preco = (item['preco'] as num? ?? 0).toDouble();
          final quantidade = (item['quantidade'] as num? ?? 0).toInt();
          totalFaturamento += preco * quantidade;
        }
      }

      double ticketMedio = totalFaturamento / pedidos.length;

      // Produto campeão de vendas
      var produtosMaisVendidosMap = await produtosMaisVendidos(limite: 1);
      String produtoMaisVendido = produtosMaisVendidosMap.isNotEmpty
          ? produtosMaisVendidosMap.keys.first
          : 'N/A';

      // Dia com mais pedidos
      var pedidosPorDiaMap = await pedidosPorDia(inicio: inicio, fim: fim);
      String diaMaisMovimentado = pedidosPorDiaMap.isNotEmpty
          ? pedidosPorDiaMap.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A';

      return {
        'totalPedidos': pedidos.length,
        'faturamentoTotal': totalFaturamento,
        'ticketMedio': ticketMedio,
        'produtoMaisVendido': produtoMaisVendido,
        'diaMaisMovimentado': diaMaisMovimentado,
      };
    } catch (e) {
      throw Exception('Erro ao calcular estatísticas gerais: $e');
    }
  }

  // Só formata datas pra DD/MM/AAAA
  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  // Converte as datas em DateTime pra poder ordenar
  int _compararDatas(String dataA, String dataB) {
    List<String> partesA = dataA.split('/');
    List<String> partesB = dataB.split('/');

    DateTime dateA = DateTime(
        int.parse(partesA[2]), int.parse(partesA[1]), int.parse(partesA[0]));
    DateTime dateB = DateTime(
        int.parse(partesB[2]), int.parse(partesB[1]), int.parse(partesB[0]));

    return dateA.compareTo(dateB);
  }
}
