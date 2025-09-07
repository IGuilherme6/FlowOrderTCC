import 'package:flutter/material.dart';
import 'package:floworder/controller/PedidoController.dart';
import '../auxiliar/Cores.dart';
import 'BarraLateral.dart';
import 'package:fl_chart/fl_chart.dart';

class TelaDashboard extends StatefulWidget {
  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  final PedidoController _pedidoController = PedidoController();
  Map<String, dynamic>? relatorio;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    final dados = await _pedidoController.gerarRelatorioDoDia();
    setState(() {
      relatorio = dados;
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/dashboard'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: carregando
                  ? Center(child: CircularProgressIndicator(color: Cores.primaryRed))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildResumo(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildGraficoStatus()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    return Row(
      children: [
        _buildCardResumo(
          "Total Vendas",
          "R\$ ${(relatorio!['totalVendas'] as double).toStringAsFixed(2)}",
        ),
        const SizedBox(width: 16),
        _buildCardResumo(
          "Pedidos",
          "${relatorio!['qtdPedidos']}",
        ),
      ],
    );
  }

  Widget _buildCardResumo(String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Cores.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Cores.borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(color: Cores.textGray, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                color: Cores.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoStatus() {
    final statusCount = relatorio!['statusCount'] as Map<String, int>;
    if (statusCount.isEmpty) {
      return Center(
        child: Text(
          "Nenhum pedido registrado hoje",
          style: TextStyle(color: Cores.textGray, fontSize: 16),
        ),
      );
    }

    final dados = statusCount.entries
        .map((e) => PieChartSectionData(
      value: e.value.toDouble(),
      title: "${e.key} (${e.value})",
      color: _statusColor(e.key),
      radius: 70,
      titleStyle: TextStyle(color: Colors.white, fontSize: 12),
    ))
        .toList();

    return _buildCardGrafico(
      "Pedidos por Status",
      PieChart(PieChartData(sections: dados)),
    );
  }

  Widget _buildCardGrafico(String titulo, Widget grafico) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Cores.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: grafico),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Aberto":
        return Colors.blue;
      case "Em Preparo":
        return Colors.orange;
      case "Pronto":
        return Colors.green;
      case "Entregue":
        return Colors.purple;
      case "Cancelado":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
