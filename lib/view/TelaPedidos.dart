import 'package:flutter/material.dart';
import 'package:floworder/controller/PedidoController.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:floworder/view/BarraLateral.dart';

class TelaPedidos extends StatefulWidget {
  @override
  State<TelaPedidos> createState() => _TelaPedidosState();
}

class _TelaPedidosState extends State<TelaPedidos> {
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color lightRed = Color(0xFFEF4444);
  static const Color backgroundBlack = Color(0xFF111827);
  static const Color cardBlack = Color(0xFF1F2937);
  static const Color textWhite = Color(0xFFF9FAFB);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color borderGray = Color(0xFF374151);

  final PedidoController _controller = PedidoController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
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
                      color: textWhite,
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
                              style: TextStyle(color: textGray),
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
                                color: cardBlack,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderGray),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mesa ${pedido.mesa.numero}',
                                    style: TextStyle(
                                      color: textWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Status: ${pedido.statusAtual}',
                                    style: TextStyle(color: textGray),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Itens:', style: TextStyle(color: textWhite)),
                                  ...pedido.itens.map((item) => Text(
                                    '- ${item.nome} (R\$ ${item.preco.toStringAsFixed(2)})',
                                    style: TextStyle(color: textGray),
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
                                                ? primaryRed
                                                : darkRed,
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
