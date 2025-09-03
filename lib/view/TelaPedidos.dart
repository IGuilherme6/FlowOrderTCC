import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:floworder/view/BarraLateral.dart';

import '../auxiliar/Cores.dart';

class TelaPedidos extends StatefulWidget {
  @override
  State<TelaPedidos> createState() => _TelaPedidosState();
}

class _TelaPedidosState extends State<TelaPedidos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          // Barra lateral
          Barralateral(currentRoute: '/pedidos'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedidos',
                    style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Conteúdo temporário
                  Center(
                    child: Text(
                      'Implementar futuramente',
                      style: TextStyle(
                        color: Cores.textGray,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
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