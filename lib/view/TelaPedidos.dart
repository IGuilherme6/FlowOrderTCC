import 'package:flutter/material.dart';
import 'package:floworder/controller/PedidoController.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:floworder/view/BarraLateral.dart';

import '../auxiliar/Cores.dart';

class TelaPedidos extends StatefulWidget {
  @override
  State<TelaPedidos> createState() => _TelaPedidosState();
}

class _TelaPedidosState extends State<TelaPedidos> {
  final PedidoController _controller = PedidoController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/pedidos'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedidos em Tempo Real',
                    style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<List<Pedido>>(
                      stream: _controller.ouvirPedidosTempoReal(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhum pedido encontrado.',
                              style: TextStyle(color: Cores.textGray),
                            ),
                          );
                        }

                        final pedidos = snapshot.data!;
                        return ListView.builder(
                          itemCount: pedidos.length,
                          itemBuilder: (context, index) {
                            final pedido = pedidos[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
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
                                    'Mesa ${pedido.mesa.numero}',
                                    style: TextStyle(
                                      color: Cores.textWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Status: ${pedido.statusAtual}',
                                    style: TextStyle(color: Cores.textGray),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Itens:', style: TextStyle(color: Cores.textWhite)),
                                  ...pedido.itens.map((item) => Text(
                                    '- ${item.nome} (R\$ ${item.preco.toStringAsFixed(2)})',
                                    style: TextStyle(color: Cores.textGray),
                                  )),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: Pedido.statusOpcoes.map((status) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: pedido.statusAtual == status
                                                ? Cores.primaryRed
                                                : Cores.darkRed,
                                          ),
                                          onPressed: () async {
                                            if (pedido.uid != null) {
                                              await _controller.atualizarStatusPedido(
                                                pedido.uid!,
                                                status,
                                              );
                                            }
                                          },
                                          child: Text(status),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
