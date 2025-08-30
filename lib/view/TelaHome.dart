import 'package:floworder/auxiliar/Cores.dart';
import 'package:flutter/material.dart';
import 'BarraLateral.dart';

class TelaHome extends StatefulWidget {
  @override
  State<TelaHome> createState() => _TelaHome();
}

class _TelaHome extends State<TelaHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/home'),
          Expanded(
            child: Stack(
              children: [
                // Imagem centralizada no fundo
                Center(
                  child: Opacity(
                    opacity: 1, // deixa mais suave
                    child: Image.asset(
                      'logo/Icone_FlowOrder.png',
                      fit: BoxFit.contain,
                      width:
                          MediaQuery.of(context).size.width *
                          0.4, // 40% da largura
                    ),
                  ),
                ),

                // Conteúdo (vazio por enquanto)
                SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
