import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:floworder/view/BarraLateral.dart';

import '../auxiliar/Cores.dart';

class TelaRelatorio extends StatefulWidget {
  @override
  State<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends State<TelaRelatorio> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          // Barra lateral
          Barralateral(currentRoute: '/relatorios'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relatórios',
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
