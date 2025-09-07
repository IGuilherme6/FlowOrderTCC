import 'package:flutter/material.dart';
import 'package:floworder/controller/CardapioController.dart';
import 'package:floworder/models/Cardapio.dart';
import 'package:floworder/view/BarraLateral.dart';
import 'package:flutter/services.dart';

import '../auxiliar/Cores.dart';

class TelaCardapio extends StatefulWidget {
  @override
  State<TelaCardapio> createState() => _TelaCardapioState();
}

class _TelaCardapioState extends State<TelaCardapio> {
  final CardapioController _controller = CardapioController();
  String _busca = '';
  String? _categoriaFiltro; // Filtro por categoria

  List<String> categorias = ['Todos', 'Bebida', 'Prato', 'Lanche', 'Outros'];

  @override
  void initState() {
    super.initState();
  }

  void _filtrarCardapios(String texto) {
    setState(() {
      _busca = texto;
    });
  }

  void _filtrarPorCategoria(String? categoria) {
    setState(() {
      _categoriaFiltro = categoria == 'Todos' ? null : categoria;
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
          backgroundColor: Cores.cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Adicionar Item',
            style: TextStyle(color: Cores.textWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(color: Cores.textGray),
                    filled: true,
                    fillColor: Cores.backgroundBlack,
                  ),
                  style: TextStyle(color: Cores.textWhite),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    labelStyle: TextStyle(color: Cores.textGray),
                    filled: true,
                    fillColor: Cores.backgroundBlack,
                  ),
                  style: TextStyle(color: Cores.textWhite),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: precoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Preço (R\$)',
                    labelStyle: TextStyle(color: Cores.textGray),
                    filled: true,
                    fillColor: Cores.backgroundBlack,
                  ),
                  style: TextStyle(color: Cores.textWhite),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  dropdownColor: Cores.backgroundBlack,
                  style: TextStyle(color: Cores.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(color: Cores.textGray),
                    filled: true,
                    fillColor: Cores.backgroundBlack,
                  ),
                  items: categorias.where((c) => c != 'Todos').map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        style: TextStyle(color: Cores.textWhite),
                      ),
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
                    descricao: descricao.isNotEmpty
                        ? descricao
                        : 'Descrição não informada',
                    preco: preco ?? 0.0,
                    categoria: categoriaSelecionada ?? 'Outros',
                  );

                  await _controller.cadastrarCardapio(novoCardapio);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item adicionado com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text('Salvar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.primaryRed,
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogEditarItem(Cardapio cardapio) {
    final nomeController = TextEditingController(text: cardapio.nome);
    final descricaoController = TextEditingController(text: cardapio.descricao);
    final precoController = TextEditingController(
      text: cardapio.preco.toString(),
    );
    String? categoriaSelecionada = cardapio.categoria;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Cores.cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('Editar Item', style: TextStyle(color: Cores.textWhite)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomeController,
                  style: TextStyle(color: Cores.textWhite),
                ),
                TextField(
                  controller: descricaoController,
                  style: TextStyle(color: Cores.textWhite),
                ),
                TextField(
                  controller: precoController,
                  style: TextStyle(color: Cores.textWhite),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  dropdownColor: Cores.backgroundBlack,
                  style: TextStyle(color: Cores.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(color: Cores.textGray),
                    filled: true,
                    fillColor: Cores.backgroundBlack,
                  ),
                  items: categorias.where((c) => c != 'Todos').map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        style: TextStyle(color: Cores.textWhite),
                      ),
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
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  cardapio.nome = nomeController.text.trim();
                  cardapio.descricao = descricaoController.text.trim();
                  cardapio.preco =
                      double.tryParse(precoController.text.trim()) ?? 0.0;
                  cardapio.categoria = categoriaSelecionada ?? 'Outros';

                  await _controller.atualizarCardapio(cardapio);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item atualizado com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
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
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Cores.backgroundBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Cores.borderGray),
        ),
        title: Text(
          'Confirmar Exclusão',
          style: TextStyle(color: Cores.textWhite),
        ),
        content: Text(
          'Tem certeza que deseja excluir este item do cardápio?',
          style: TextStyle(color: Cores.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Cores.primaryRed)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);

              try {
                await _controller.deletarCardapio(cardapioId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item excluído com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir item: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Excluir', style: TextStyle(color: Cores.primaryRed)),
          ),
        ],
      ),
    );
  }

  void _alternarSuspensao(Cardapio cardapio) async {
    try {
      await _controller.suspenderCardapio(cardapio.uid, !cardapio.ativo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cardapio.ativo ? 'Item suspenso' : 'Item reativado'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Cores.backgroundBlack,
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
                    color: Cores.textWhite,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),

                // Filtros
                Row(
                  children: [
                    // Busca por texto
                    Expanded(
                      child: TextField(
                        onChanged: _filtrarCardapios,
                        style: TextStyle(color: Cores.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Buscar item...',
                          hintStyle: TextStyle(color: Cores.textGray),
                          prefixIcon: Icon(Icons.search, color: Cores.textGray),
                          filled: true,
                          fillColor: Cores.cardBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Cores.borderGray),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Filtro por categoria
                    DropdownButton<String>(
                      value: _categoriaFiltro ?? 'Todos',
                      dropdownColor: Cores.cardBlack,
                      style: TextStyle(color: Cores.textWhite),
                      items: categorias.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: _filtrarPorCategoria,
                    ),
                    SizedBox(width: 16),

                    // Botão adicionar item
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogAdicionarItem,
                      icon: Icon(Icons.add),
                      label: Text('Adicionar Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Cores.primaryRed,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        textStyle: TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Stream de cardápios
                // Replace the existing StreamBuilder section with this:
                FutureBuilder<Stream<List<Cardapio>>>(
                  future: _controller.buscarCardapioTempoReal(),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (futureSnapshot.hasError) {
                      return Text(
                        'Erro: ${futureSnapshot.error}',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    if (!futureSnapshot.hasData) {
                      return Text(
                        'Stream não disponível',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    return StreamBuilder<List<Cardapio>>(
                      stream: futureSnapshot.data!,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Erro: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final lista = snapshot.data ?? [];
                        final filtrados = lista.where((item) {
                          final textoOk =
                              _busca.trim().isEmpty ||
                              item.nome.toLowerCase().contains(
                                _busca.toLowerCase(),
                              ) ||
                              item.descricao.toLowerCase().contains(
                                _busca.toLowerCase(),
                              );

                          final categoriaOk =
                              _categoriaFiltro == null ||
                              item.categoria == _categoriaFiltro;

                          return textoOk && categoriaOk;
                        }).toList();

                        if (filtrados.isEmpty) {
                          return Text(
                            'Nenhum item encontrado.',
                            style: TextStyle(color: Cores.textGray),
                          );
                        }

                        final Map<String, List<Cardapio>> agrupadoPorCategoria =
                            {};
                        for (var item in filtrados) {
                          agrupadoPorCategoria
                              .putIfAbsent(item.categoria, () => [])
                              .add(item);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: agrupadoPorCategoria.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exibe título da categoria só se não estiver filtrando
                                if (_categoriaFiltro == null)
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: Cores.textWhite,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (_categoriaFiltro == null)
                                  SizedBox(height: 12),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: entry.value.map((cardapio) {
                                        return Container(
                                          width: constraints.maxWidth > 900
                                              ? constraints.maxWidth / 3 - 20
                                              : constraints.maxWidth,
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Cores.cardBlack,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Cores.borderGray,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cardapio.nome,
                                                style: TextStyle(
                                                  color: Cores.textWhite,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                cardapio.descricao,
                                                style: TextStyle(
                                                  color: Cores.textGray,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'R\$ ${cardapio.preco.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Cores.textWhite,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                cardapio.ativo
                                                    ? 'Ativo'
                                                    : 'Suspenso',
                                                style: TextStyle(
                                                  color: cardapio.ativo
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: Cores.lightRed,
                                                    ),
                                                    onPressed: () =>
                                                        _mostrarDialogEditarItem(
                                                          cardapio,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      cardapio.ativo
                                                          ? Icons.block
                                                          : Icons.check_circle,
                                                      color: Colors.amber,
                                                    ),
                                                    onPressed: () =>
                                                        _alternarSuspensao(
                                                          cardapio,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        _mostrarDialogExcluirItem(
                                                          cardapio.uid,
                                                        ),
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
                                SizedBox(height: 24),
                              ],
                            );
                          }).toList(),
                        );
                      },
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
