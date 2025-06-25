import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:floworder/view/BarraLateral.dart';

class TelaMesa extends StatefulWidget {
  @override
  State<TelaMesa> createState() => _TelaMesaState();
}

class _TelaMesaState extends State<TelaMesa> {
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color lightRed = Color(0xFFEF4444);
  static const Color backgroundBlack = Color(0xFF111827);
  static const Color cardBlack = Color(0xFF1F2937);
  static const Color textWhite = Color(0xFFF9FAFB);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color borderGray = Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Row(
        children: [
          // Barra lateral
          Barralateral(currentRoute: '/mesas'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerenciar Mesas',
                    style: TextStyle(
                      color: textWhite,
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
                        color: textGray,
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
