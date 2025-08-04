import 'package:floworder/controller/MesaController.dart';
import 'package:flutter/material.dart';
import 'package:floworder/view/BarraLateral.dart';
import 'package:flutter/services.dart';
import '../models/Mesa.dart';

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

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final MesaController _mesaController = MesaController();

  Future<void> _excluirMesa(String uid) async {
    try {
      String msg = await _mesaController.deletarMesa(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _adicionarMesa(String nome, String numero) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      Mesa novaMesa = Mesa();
      novaMesa.nome = nome;
      novaMesa.numero = int.tryParse(numero) ?? 0;

      String mensagem = await _mesaController.cadastrarMesa(novaMesa);
      _nomeController.clear();
      _numeroController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.blue),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editarMesaDialog(Mesa mesa) async {
    TextEditingController nomeEditController =
    TextEditingController(text: mesa.nome);
    TextEditingController numeroEditController =
    TextEditingController(text: mesa.numero.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBlack,
          title: Text('Editar Mesa', style: TextStyle(color: textWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroEditController,
                style: TextStyle(color: textWhite),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número da Mesa',
                  labelStyle: TextStyle(color: textGray),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: nomeEditController,
                style: TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: 'Nome da Mesa',
                  labelStyle: TextStyle(color: textGray),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: textGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
              onPressed: () async {
                try {
                  mesa.nome = nomeEditController.text;
                  mesa.numero = int.tryParse(numeroEditController.text) ?? mesa.numero;
                  await _mesaController.atualizarMesa(mesa);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mesa atualizada com sucesso'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('Salvar', style: TextStyle(color: textWhite)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/mesas'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 12),
                      Text(
                        'Gerenciar Mesas',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  /// Layout principal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// CARD: Listagem
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardBlack,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderGray),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.list, color: lightRed),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mesas cadastradas',
                                    style: TextStyle(
                                      color: textWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              StreamBuilder<List<Mesa>>(
                                stream: _mesaController.streamMesasDoGerente(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.red));
                                  }
                                  final mesas = snapshot.data ?? [];
                                  if (mesas.isEmpty) {
                                    return Text('Nenhuma mesa cadastrada', style: TextStyle(color: textGray));
                                  }
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 40,
                                      headingRowColor: MaterialStateColor.resolveWith((states) => darkRed),
                                      columns: [
                                        DataColumn(label: Text('Número', style: TextStyle(color: textWhite))),
                                        DataColumn(label: Text('Nome', style: TextStyle(color: textWhite))),
                                        DataColumn(label: Text('Editar', style: TextStyle(color: textWhite))),
                                        DataColumn(label: Text('Deletar', style: TextStyle(color: textWhite))),
                                      ],
                                      rows: mesas.map((mesa) => DataRow(cells: [
                                        DataCell(Text(mesa.numero.toString(), style: TextStyle(color: textWhite))),
                                        DataCell(Text(mesa.nome.isNotEmpty ? mesa.nome : 'Mesa ${mesa.numero}', style: TextStyle(color: textWhite))),
                                        DataCell(IconButton(
                                          icon: Icon(Icons.edit, color: Colors.amber),
                                          tooltip: 'Editar mesa',
                                          onPressed: () => _editarMesaDialog(mesa),
                                        )),
                                        DataCell(IconButton(
                                          icon: Icon(Icons.delete_outline, color: lightRed),
                                          tooltip: 'Excluir mesa',
                                          onPressed: () => _excluirMesa(mesa.uid),
                                        )),
                                      ])).toList(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 24),

                      /// CARD: Cadastro
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardBlack,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderGray),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.add_box, color: lightRed),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cadastrar nova mesa',
                                    style: TextStyle(
                                      color: textWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _numeroController,
                                      style: TextStyle(color: textWhite),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        labelText: 'Número da Mesa',
                                        labelStyle: TextStyle(color: textGray),
                                        border: OutlineInputBorder(),
                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderGray)),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Número obrigatório';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    TextFormField(
                                      controller: _nomeController,
                                      style: TextStyle(color: textWhite),
                                      decoration: InputDecoration(
                                        labelText: 'Nome da Mesa (opcional)',
                                        labelStyle: TextStyle(color: textGray),
                                        border: OutlineInputBorder(),
                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderGray)),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryRed,
                                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: Icon(Icons.check, color: textWhite),
                                        label: Text('Cadastrar Mesa', style: TextStyle(color: textWhite)),
                                        onPressed: () => _adicionarMesa(_nomeController.text, _numeroController.text),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
