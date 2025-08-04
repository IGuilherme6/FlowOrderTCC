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

  List<String> categorias = ['Bebida', 'Prato', 'Lanche', 'Outros'];

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

  void _mostrarDialogAdicionarItem() {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();
    final precoController = TextEditingController();
    String? categoriaSelecionada = 'Outros';

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
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  dropdownColor: backgroundBlack,
                  style: TextStyle(color: textWhite),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(color: textGray),
                    filled: true,
                    fillColor: backgroundBlack,
                  ),
                  items: categorias.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: TextStyle(color: textWhite)),
                    );
                  }).toList(),
                  onChanged: (value) => categoriaSelecionada = value,
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

                  final novoCardapio = Cardapio(
                    nome: nome.isNotEmpty ? nome : 'Item sem nome',
                    descricao: descricao.isNotEmpty ? descricao : 'Descrição não informada',
                    preco: preco ?? 0.0,
                    categoria: categoriaSelecionada ?? 'Outros',
                  );

                  await _controller.cadastrarCardapio(novoCardapio);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item adicionado com sucesso!')));
                  _carregarCardapios();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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

  void _mostrarDialogEditarItem(Cardapio cardapio) {
    final nomeController = TextEditingController(text: cardapio.nome);
    final descricaoController = TextEditingController(text: cardapio.descricao);
    final precoController = TextEditingController(text: cardapio.preco.toString());
    String? categoriaSelecionada = cardapio.categoria;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Editar Item', style: TextStyle(color: textWhite)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nomeController, style: TextStyle(color: textWhite)),
                TextField(controller: descricaoController, style: TextStyle(color: textWhite)),
                TextField(
                  controller: precoController,
                  style: TextStyle(color: textWhite),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  dropdownColor: backgroundBlack,
                  style: TextStyle(color: textWhite),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(color: textGray),
                    filled: true,
                    fillColor: backgroundBlack,
                  ),
                  items: categorias.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: TextStyle(color: textWhite)),
                    );
                  }).toList(),
                  onChanged: (value) => categoriaSelecionada = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  cardapio.nome = nomeController.text.trim();
                  cardapio.descricao = descricaoController.text.trim();
                  cardapio.preco = double.tryParse(precoController.text.trim()) ?? 0.0;
                  cardapio.categoria = categoriaSelecionada ?? 'Outros';

                  await _controller.atualizarCardapio(cardapio);
                  Navigator.pop(context);
                  _carregarCardapios();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item atualizado com sucesso!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogExcluirItem(String cardapioId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar exclusão'),
          content: Text('Deseja realmente excluir este item?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _controller.excluirCardapio(cardapioId);
                  Navigator.pop(context);
                  _carregarCardapios();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item excluído com sucesso!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _alternarSuspensao(Cardapio cardapio) async {
    try {
      await _controller.suspenderCardapio(cardapio.uid, !cardapio.ativo);
      _carregarCardapios();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cardapio.ativo ? 'Item suspenso' : 'Item reativado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Cardapio>> agrupadoPorCategoria = {};
    for (var item in _filtrados) {
      agrupadoPorCategoria.putIfAbsent(item.categoria, () => []).add(item);
    }

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
                  Text('Gerenciamento de Cardápio', style: TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.bold)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderGray)),
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
                      ? Text('Nenhum item encontrado.', style: TextStyle(color: textGray))
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: agrupadoPorCategoria.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: TextStyle(color: textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: entry.value.map((cardapio) {
                                  return Container(
                                    width: constraints.maxWidth > 900 ? constraints.maxWidth / 3 - 20 : constraints.maxWidth,
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardBlack,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderGray),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cardapio.nome, style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 8),
                                        Text(cardapio.descricao, style: TextStyle(color: textGray)),
                                        SizedBox(height: 8),
                                        Text('R\$ ${cardapio.preco.toStringAsFixed(2)}', style: TextStyle(color: textWhite)),
                                        SizedBox(height: 8),
                                        Text(cardapio.ativo ? 'Ativo' : 'Suspenso', style: TextStyle(color: cardapio.ativo ? Colors.green : Colors.red)),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(icon: Icon(Icons.edit, color: lightRed), onPressed: () => _mostrarDialogEditarItem(cardapio)),
                                            IconButton(
                                              icon: Icon(cardapio.ativo ? Icons.block : Icons.check_circle, color: Colors.amber),
                                              onPressed: () => _alternarSuspensao(cardapio),
                                            ),
                                            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _mostrarDialogExcluirItem(cardapio.uid)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
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
