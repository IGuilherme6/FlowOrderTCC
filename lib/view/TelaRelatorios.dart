import 'package:flutter/material.dart';
import 'package:floworder/controller/RelatorioController.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaRelatorios extends StatefulWidget {
  @override
  _TelaRelatoriosState createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final RelatorioController _relatorioController = RelatorioController();
  String filtroSelecionado = "Diário";
  final DateFormat formatoData = DateFormat('dd/MM/yyyy');

  // Função para calcular período baseado no filtro
  Map<String, DateTime> _calcularPeriodo() {
    DateTime agora = DateTime.now();
    DateTime inicio;

    switch (filtroSelecionado) {
      case "Diário":
        inicio = DateTime(agora.year, agora.month, agora.day);
        break;
      case "Semanal":
        inicio = agora.subtract(Duration(days: agora.weekday - 1));
        inicio = DateTime(inicio.year, inicio.month, inicio.day);
        break;
      case "Mensal":
        inicio = DateTime(agora.year, agora.month, 1);
        break;
      case "Anual":
        inicio = DateTime(agora.year, 1, 1);
        break;
      default:
        inicio = DateTime(agora.year, agora.month, agora.day);
    }

    return {'inicio': inicio, 'fim': agora};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📊 Relatórios"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// FILTRO DE PERÍODO
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: filtroSelecionado,
                isExpanded: true,
                underline: SizedBox(),
                items: ["Diário", "Semanal", "Mensal", "Anual"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (valor) {
                  setState(() {
                    filtroSelecionado = valor!;
                    // Limpar cache quando filtro muda
                    _relatorioController.clearCache();
                  });
                },
              ),
            ),
            SizedBox(height: 20),

            /// ESTATÍSTICAS GERAIS
            Text(
              "📊 Resumo Geral",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<Map<String, dynamic>>(
              future: () {
                final periodo = _calcularPeriodo();
                return _relatorioController.estatisticasGerais(
                  inicio: periodo['inicio'],
                  fim: periodo['fim'],
                );
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Erro: ${snapshot.error}");
                }
                if (!snapshot.hasData) {
                  return Text("Nenhum dado encontrado");
                }

                final stats = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total de Pedidos:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("${stats['totalPedidos']}"),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Faturamento Total:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("R\$ ${(stats['faturamentoTotal'] as double).toStringAsFixed(2)}"),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Ticket Médio:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("R\$ ${(stats['ticketMedio'] as double).toStringAsFixed(2)}"),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Produto Mais Vendido:", style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text("${stats['produtoMaisVendido']}", textAlign: TextAlign.end)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),

            /// RELATÓRIO DE PEDIDOS RECENTES
            Text(
              "📋 Pedidos Recentes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _relatorioController.listarPedidos(limite: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Erro: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text("Nenhum pedido encontrado");
                }

                return Column(
                  children: snapshot.data!.map((pedido) {
                    final horario = (pedido['horario'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final itens = pedido['itens'] as List<dynamic>? ?? [];

                    // Calcular total do pedido
                    double total = 0.0;
                    for (var item in itens) {
                      final preco = (item['preco'] as num? ?? 0).toDouble();
                      final quantidade = (item['quantidade'] as num? ?? 0).toInt();
                      total += preco * quantidade;
                    }

                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.shopping_cart, color: Colors.deepPurple),
                        title: Text("Pedido #${pedido['uid'] ?? 'N/A'}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mesa: ${pedido['mesa'] ?? 'N/A'}"),
                            Text("Total: R\$ ${total.toStringAsFixed(2)}"),
                            Text("Status: ${pedido['statusAtual'] ?? 'N/A'}"),
                          ],
                        ),
                        trailing: Text(formatoData.format(horario)),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),

            /// RELATÓRIO PRODUTOS MAIS VENDIDOS
            Text(
              "🍔 Top 10 Produtos Mais Vendidos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: _relatorioController.produtosMaisVendidos(limite: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Erro: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text("Nenhum produto encontrado");
                }

                return Column(
                  children: snapshot.data!.entries.map((e) {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.fastfood, color: Colors.orange),
                        title: Text(e.key),
                        trailing: Chip(
                          label: Text("${e.value}"),
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),

            /// RELATÓRIO FATURAMENTO POR PRODUTO
            Text(
              "💰 Faturamento por Produto",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<Map<String, double>>(
              future: _relatorioController.faturamentoPorProduto(limite: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Erro: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text("Nenhum dado encontrado");
                }

                return Column(
                  children: snapshot.data!.entries.map((e) {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.attach_money, color: Colors.green),
                        title: Text(e.key),
                        trailing: Text(
                          "R\$ ${e.value.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),

            /// RELATÓRIO PEDIDOS POR DIA
            Text(
              "📆 Pedidos por Dia ($filtroSelecionado)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: () {
                final periodo = _calcularPeriodo();
                return _relatorioController.pedidosPorDia(
                  inicio: periodo['inicio'],
                  fim: periodo['fim'],
                );
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Erro: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text("Nenhum dado encontrado para o período selecionado");
                }

                return Column(
                  children: snapshot.data!.entries.map((e) {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: Colors.blue),
                        title: Text(e.key),
                        trailing: Chip(
                          label: Text("${e.value}"),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),

            /// RELATÓRIO FATURAMENTO POR DIA
            Text(
              "💵 Faturamento por Dia ($filtroSelecionado)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            FutureBuilder<Map<String, double>>(
              future: () {
                final periodo = _calcularPeriodo();
                return _relatorioController.faturamentoPorDia(
                  inicio: periodo['inicio'],
                  fim: periodo['fim'],
                );
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Erro: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text("Nenhum dado encontrado para o período selecionado");
                }

                return Column(
                  children: snapshot.data!.entries.map((e) {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.monetization_on, color: Colors.green),
                        title: Text(e.key),
                        trailing: Text(
                          "R\$ ${e.value.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}