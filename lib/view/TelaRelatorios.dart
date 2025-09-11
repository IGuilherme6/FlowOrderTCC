import 'package:flutter/material.dart';
import 'package:floworder/controller/RelatorioController.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:intl/intl.dart'; // para formatar datas

class TelaRelatorios extends StatefulWidget {
  @override
  _TelaRelatoriosState createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final RelatorioController _relatorioController = RelatorioController();
  String filtroSelecionado = "Diário";

  final DateFormat formatoData = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📊 Relatórios"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// FILTRO DE PERÍODO
            DropdownButton<String>(
              value: filtroSelecionado,
              items: ["Diário", "Semanal", "Mensal", "Anual"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  filtroSelecionado = valor!;
                });
              },
            ),
            SizedBox(height: 20),

            /// RELATÓRIO DE PEDIDOS
            Text(
              "📋 Pedidos Feitos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<Pedido>>(
              future: _relatorioController.listarPedidos(),
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
                  children: snapshot.data!.map((p) {
                    return ListTile(
                      leading: Icon(Icons.shopping_cart),
                      title: Text("Pedido #${p.uid} - Mesa ${p.mesa.uid}"),
                      subtitle: Text(
                        "Total: R\$ ${p.total.toStringAsFixed(2)}",
                      ),
                      trailing: Text(formatoData.format(p.horario)),
                    );
                  }).toList(),
                );
              },
            ),
            Divider(),

            /// RELATÓRIO PRODUTOS MAIS VENDIDOS
            Text(
              "🍔 Produtos Mais Vendidos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<Map<String, int>>(
              future: _relatorioController.produtosMaisVendidos(),
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
                    return ListTile(
                      leading: Icon(Icons.fastfood),
                      title: Text(e.key),
                      trailing: Text("Qtd: ${e.value}"),
                    );
                  }).toList(),
                );
              },
            ),
            Divider(),

            /// RELATÓRIO PEDIDOS POR DIA
            Text(
              "📆 Pedidos por Dia",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<Map<String, int>>(
              future: _relatorioController.pedidosPorDia(),
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
                    return ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text(e.key),
                      trailing: Text("${e.value} pedidos"),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
