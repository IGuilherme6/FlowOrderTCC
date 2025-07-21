import 'package:flutter/material.dart';
import 'package:floworder/controller/CardapioController.dart';
import 'package:floworder/models/Cardapio.dart';
import 'package:floworder/view/BarraLateral.dart';

class TelaCardapio extends StatefulWidget {
  @override
  State<TelaCardapio> createState() => _TelaCardapioState();
}

class _TelaCardapioState extends State<TelaCardapio> {
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color lightRed = Color(0xFFEF4444);
  static const Color backgroundBlack = Color(0xFF111827);
  static const Color cardBlack = Color(0xFF1F2937);
  static const Color textWhite = Color(0xFFF9FAFB);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color borderGray = Color(0xFF374151);

  final CardapioController _controller = CardapioController();
  List<Cardapio> _cardapios = [];
  List<Cardapio> _filtrados = [];
  bool _loading = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregarCardapios();
  }

  Future<void> _carregarCardapios() async {
    try {
      List<Cardapio> lista = await _controller.buscarCardapiosDoGerente();
      setState(() {
        _cardapios = lista;
        _filtrados = lista;
        _loading = false;
      });
    } catch (e) {
      print('Erro ao carregar cardápios: $e');
      setState(() => _loading = false);
    }
  }

  void _filtrarCardapios(String texto) {
    setState(() {
      _busca = texto;
      _filtrados = _cardapios.where((item) =>
      item.nome.toLowerCase().contains(texto.toLowerCase()) ||
          item.descricao.toLowerCase().contains(texto.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/cardapio'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerenciamento de Cardápio',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: _filtrarCardapios,
                          style: TextStyle(color: textWhite),
                          decoration: InputDecoration(
                            hintText: 'Buscar item...',
                            hintStyle: TextStyle(color: textGray),
                            prefixIcon: Icon(Icons.search, color: textGray),
                            filled: true,
                            fillColor: cardBlack,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderGray),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogAdicionarItem,
                        icon: Icon(Icons.add),
                        label: Text('Adicionar Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _loading
                      ? Center(child: CircularProgressIndicator())
                      : _filtrados.isEmpty
                      ? Text(
                    'Nenhum item encontrado.',
                    style: TextStyle(color: textGray),
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _filtrados.map((cardapio) {
                          return Container(
                            width: constraints.maxWidth > 900
                                ? constraints.maxWidth / 3 - 20
                                : constraints.maxWidth,
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
                                  cardapio.nome,
                                  style: TextStyle(
                                    color: textWhite,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  cardapio.descricao,
                                  style: TextStyle(color: textGray),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'R\$ ${cardapio.preco.toStringAsFixed(2)}',
                                  style: TextStyle(color: textWhite),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: lightRed),
                                      onPressed: () {
                                        // Editar
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.block, color: Colors.amber),
                                      onPressed: () {
                                        // Suspender
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        // Excluir
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _mostrarDialogAdicionarItem() {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();
    final precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Adicionar Item', style: TextStyle(color: textWhite)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(color: textGray),
                    filled: true,
                    fillColor: backgroundBlack,
                  ),
                  style: TextStyle(color: textWhite),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    labelStyle: TextStyle(color: textGray),
                    filled: true,
                    fillColor: backgroundBlack,
                  ),
                  style: TextStyle(color: textWhite),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: precoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Preço (R\$)',
                    labelStyle: TextStyle(color: textGray),
                    filled: true,
                    fillColor: backgroundBlack,
                  ),
                  style: TextStyle(color: textWhite),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final nome = nomeController.text.trim();
                  final descricao = descricaoController.text.trim();
                  final preco = double.tryParse(precoController.text.trim());

                  final novoCardapio = Cardapio();
                  novoCardapio.nome = nome.isNotEmpty ? nome : 'Item sem nome';
                  novoCardapio.descricao = descricao.isNotEmpty ? descricao : 'Descrição não informada';
                  novoCardapio.preco = preco ?? 0.0;

                  await _controller.cadastrarCardapio(novoCardapio);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Item adicionado com sucesso!'))
                  );
                  _carregarCardapios(); // Recarrega lista
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()))
                  );
                }
              },
              child: Text('Salvar'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            ),
          ],
        );
      },
    );
  }
}
