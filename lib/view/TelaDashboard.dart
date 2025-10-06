import 'package:flutter/material.dart';
import 'package:floworder/controller/PedidoController.dart';
import '../auxiliar/Cores.dart';
import 'BarraLateral.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/GlobalUser.dart';

class TelaDashboard extends StatefulWidget {
  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  final PedidoController _pedidoController = PedidoController();
  Map<String, dynamic>? relatorio;
  bool carregando = true;
  bool semanal = false; // 🔹 filtro atual

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() => carregando = true);
    final dados = await _pedidoController.gerarRelatorio(semanal: semanal);
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: carregando
                    ? Center(
                  key: ValueKey("loading"),
                  child: CircularProgressIndicator(color: Cores.primaryRed),
                )
                    : Column(
                  key: ValueKey(semanal ? "semanal" : "diario"),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Cores.textWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ToggleButtons(
                          isSelected: [!semanal, semanal],
                          onPressed: (index) {
                            setState(() {
                              semanal = index == 1;
                            });
                            _carregarRelatorio();
                          },
                          color: Cores.textGray,
                          selectedColor: Cores.textWhite,
                          fillColor: Cores.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Diário"),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Semanal"),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildResumo(),
                    const SizedBox(height: 24),
                    _buildGraficos(), // status + métodos de pagamento lado a lado
                  ],
                ),
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
          "Nenhum pedido encontrado no período",
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
      semanal
          ? "Pedidos por Status (${_formatarData(relatorio!['periodoInicio'])} a ${_formatarData(relatorio!['periodoFim'])})"
          : "Pedidos por Status (Hoje)",
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

  Widget _buildGraficos() {
    return Expanded(
      child: Row(
        children: [
          Expanded(child: _buildGraficoStatus()),
          const SizedBox(width: 16),
          Expanded(child: _buildGraficoPagamento()),
        ],
      ),
    );
  }

  Widget _buildGraficoPagamento() {
    final pagamentoPorMetodo =
    relatorio!['pagamentoPorMetodo'] as Map<String, double>;

    final dados = pagamentoPorMetodo.entries
        .where((e) => e.value > 0)
        .map((e) => PieChartSectionData(
      value: e.value,
      title: "${e.key}\nR\$ ${e.value.toStringAsFixed(2)}",
      radius: 70,
      titleStyle: TextStyle(color: Colors.white, fontSize: 12),
      color: _corPagamento(e.key),
    ))
        .toList();

    if (dados.isEmpty) {
      return _buildCardGrafico(
        "Vendas por Método de Pagamento",
        Center(
          child: Text(
            "Nenhum pagamento registrado no período",
            style: TextStyle(color: Cores.textGray, fontSize: 16),
          ),
        ),
      );
    }

    return _buildCardGrafico(
      "Vendas por Método de Pagamento",
      PieChart(PieChartData(sections: dados)),
    );
  }

  Color _corPagamento(String metodo) {
    switch (metodo) {
      case "Dinheiro":
        return Colors.green;
      case "Cartão":
        return Colors.blue;
      case "PIX":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}";
  }

}
