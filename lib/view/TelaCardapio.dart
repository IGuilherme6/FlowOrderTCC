import 'package:flutter/material.dart';
import 'package:floworder/controller/CardapioController.dart';
import 'package:floworder/models/Cardapio.dart';
import 'package:floworder/view/BarraLateral.dart';
import 'package:flutter/services.dart';

import '../auxiliar/Cores.dart'; // Certifique-se que este import está correto
import '../models/Categoria.dart'; // Importe o modelo Categoria

class TelaCardapio extends StatefulWidget {
  @override
  State<TelaCardapio> createState() => _TelaCardapioState();
}

class _TelaCardapioState extends State<TelaCardapio> {
  final CardapioController _controller = CardapioController();
  String _busca = '';
  String? _categoriaFiltro; // Filtro por categoria

  // Lista dinâmica de categorias para o Dropdown principal
  List<String> _categoriasDisponiveis = [];
  // Lista de objetos Categoria para o gerenciamento
  List<Categoria> _categoriasGerenciamento = [];

  @override
  void initState() {
    super.initState();
    _carregarCategorias(); // Chama o método para carregar categorias
  }

  // Método para carregar categorias dinamicamente
  void _carregarCategorias() async {
    // Carrega categorias para o Dropdown de filtro
    (await _controller.buscarCategoriasTempoReal()).listen((listaNomes) {
      setState(() {
        _categoriasDisponiveis = listaNomes;
        // Garante que o filtro atual permaneça válido
        if (_categoriaFiltro != null && !_categoriasDisponiveis.contains(_categoriaFiltro)) {
          _categoriaFiltro = 'Todos';
        }
      });
    });

    // Carrega categorias para o modal de gerenciamento
    (await _controller.buscarCategoriasGerenciamento()).listen((listaCategorias) {
      setState(() {
        _categoriasGerenciamento = listaCategorias;
      });
    });
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
    // Inicializa com uma categoria válida ou a primeira disponível (excluindo 'Todos')
    String? categoriaSelecionada = _categoriasDisponiveis.isNotEmpty && _categoriasDisponiveis.any((c) => c != 'Todos')
        ? _categoriasDisponiveis.firstWhere((c) => c != 'Todos')
        : 'Outros';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Cores.cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Adicionar Item', style: TextStyle(color: Cores.textWhite)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(labelText: 'Nome', labelStyle: TextStyle(color: Cores.textGray), filled: true, fillColor: Cores.backgroundBlack),
                  style: TextStyle(color: Cores.textWhite),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(labelText: 'Descrição', labelStyle: TextStyle(color: Cores.textGray), filled: true, fillColor: Cores.backgroundBlack),
                  style: TextStyle(color: Cores.textWhite),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: precoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))],
                  decoration: InputDecoration(labelText: 'Preço (R\$)', labelStyle: TextStyle(color: Cores.textGray), filled: true, fillColor: Cores.backgroundBlack),
                  style: TextStyle(color: Cores.textWhite),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  dropdownColor: Cores.backgroundBlack,
                  style: TextStyle(color: Cores.textWhite),
                  decoration: InputDecoration(labelText: 'Categoria', labelStyle: TextStyle(color: Cores.textGray), filled: true, fillColor: Cores.backgroundBlack),
                  items: _categoriasDisponiveis.where((c) => c != 'Todos').map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(color: Cores.textWhite)));
                  }).toList(),
                  onChanged: (value) => categoriaSelecionada = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: Colors.grey))),
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
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
                }
              },
              child: Text('Salvar'),
              style: ElevatedButton.styleFrom(backgroundColor: Cores.primaryRed),
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
          backgroundColor: Cores.cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Editar Item', style: TextStyle(color: Cores.textWhite)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nomeController, style: TextStyle(color: Cores.textWhite)),
                TextField(controller: descricaoController, style: TextStyle(color: Cores.textWhite)),
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
                  decoration: InputDecoration(labelText: 'Categoria', labelStyle: TextStyle(color: Cores.textGray), filled: true, fillColor: Cores.backgroundBlack),
                  items: _categoriasDisponiveis.where((c) => c != 'Todos').map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(color: Cores.textWhite)));
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item atualizado com sucesso!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Cores.borderGray)),
        title: Text('Confirmar Exclusão', style: TextStyle(color: Cores.textWhite)),
        content: Text('Tem certeza que deseja excluir este item do cardápio?', style: TextStyle(color: Cores.textWhite)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: Cores.primaryRed))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              try {
                await _controller.deletarCardapio(cardapioId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item excluído com sucesso!'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir item: ${e.toString()}'), backgroundColor: Colors.red));
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
      // O parâmetro `suspender` no `_controller.suspenderCardapio` é o *novo estado*.
      // Se `cardapio.ativo` é `true` (ativo), queremos suspender, então o novo estado é `false`.
      // Se `cardapio.ativo` é `false` (suspenso), queremos reativar, então o novo estado é `true`.
      await _controller.suspenderCardapio(cardapio.uid, !cardapio.ativo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cardapio.ativo ? 'Item suspenso' : 'Item reativado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    }
  }

  // Novo modal para gerenciar categorias
  void _mostrarDialogGerenciarCategorias() {
    final nomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Cores.cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Gerenciar Categorias', style: TextStyle(color: Cores.textWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nova Categoria', labelStyle: TextStyle(color: Cores.textGray), filled: true, fillColor: Cores.backgroundBlack),
                style: TextStyle(color: Cores.textWhite),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (nomeController.text.isNotEmpty) {
                    try {
                      await _controller.adicionarCategoria(nomeController.text);
                      nomeController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Categoria adicionada com sucesso!')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
                    }
                  }
                },
                child: Text('Adicionar'),
                style: ElevatedButton.styleFrom(backgroundColor: Cores.primaryRed),
              ),
              SizedBox(height: 24),
              // Lista de categorias existentes para edição/exclusão
              if (_categoriasGerenciamento.isNotEmpty)
                ..._categoriasGerenciamento.map((categoria) {
                  return ListTile(
                    title: Text(categoria.nome, style: TextStyle(color: Cores.textWhite)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Cores.lightRed),
                          onPressed: () => _mostrarDialogEditarCategoria(categoria),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await _controller.deletarCategoria(categoria.uid);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Categoria excluída!')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar', style: TextStyle(color: Colors.grey))),
          ],
        );
      },
    );
  }

  // Novo modal para editar categoria
  void _mostrarDialogEditarCategoria(Categoria categoria) {
    final nomeController = TextEditingController(text: categoria.nome);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Cores.cardBlack,
          title: Text('Editar Categoria', style: TextStyle(color: Cores.textWhite)),
          content: TextField(
            controller: nomeController,
            style: TextStyle(color: Cores.textWhite),
            decoration: InputDecoration(labelText: 'Novo Nome', labelStyle: TextStyle(color: Cores.textGray)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isNotEmpty) {
                  try {
                    await _controller.atualizarCategoria(categoria.uid, nomeController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Categoria atualizada!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
                  }
                }
              },
              child: Text('Salvar'),
              style: ElevatedButton.styleFrom(backgroundColor: Cores.primaryRed),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Cores.backgroundBlack,
    body: Row(
      children: [
        Barralateral(currentRoute: '/cardapio'), // Certifique-se que o import e a classe existem
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerenciamento de Cardápio',
                  style: TextStyle(color: Cores.textWhite, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),

                // Filtros
                Row(
                  children: [
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Cores.borderGray)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Filtro por categoria (usa _categoriasDisponiveis)
                    DropdownButton<String>(
                      value: _categoriaFiltro ?? 'Todos',
                      dropdownColor: Cores.cardBlack,
                      style: TextStyle(color: Cores.textWhite),
                      items: _categoriasDisponiveis.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: _filtrarPorCategoria,
                    ),
                    SizedBox(width: 16),

                    // Novo botão para gerenciar categorias
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogGerenciarCategorias,
                      icon: Icon(Icons.folder),
                      label: Text('Gerenciar Categorias'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Cores.lightRed,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Botão adicionar item
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogAdicionarItem,
                      icon: Icon(Icons.add),
                      label: Text('Adicionar Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Cores.primaryRed,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Stream de cardápios
                FutureBuilder<Stream<List<Cardapio>>>(
                  future: _controller.buscarCardapioTempoReal(),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (futureSnapshot.hasError) {
                      return Text('Erro ao carregar stream: ${futureSnapshot.error}', style: TextStyle(color: Colors.red));
                    }
                    if (!futureSnapshot.hasData) {
                      return Text('Stream indisponível.', style: TextStyle(color: Colors.red));
                    }

                    return StreamBuilder<List<Cardapio>>(
                      stream: futureSnapshot.data!,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Erro no stream: ${snapshot.error}', style: TextStyle(color: Colors.red));
                        }

                        final lista = snapshot.data ?? [];
                        final filtrados = lista.where((item) {
                          final textoOk = _busca.trim().isEmpty ||
                              item.nome.toLowerCase().contains(_busca.toLowerCase()) ||
                              item.descricao.toLowerCase().contains(_busca.toLowerCase());

                          final categoriaOk = _categoriaFiltro == null || item.categoria == _categoriaFiltro;

                          return textoOk && categoriaOk;
                        }).toList();

                        if (filtrados.isEmpty) {
                          return Text('Nenhum item encontrado.', style: TextStyle(color: Cores.textGray));
                        }

                        final Map<String, List<Cardapio>> agrupadoPorCategoria = {};
                        for (var item in filtrados) {
                          agrupadoPorCategoria.setdefault(item.categoria, []).add(item);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: agrupadoPorCategoria.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_categoriaFiltro == null)
                                  Text(entry.key, style: TextStyle(color: Cores.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                                if (_categoriaFiltro == null) SizedBox(height: 12),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Ajusta o número de colunas baseado na largura da tela
                                    int columns = constraints.maxWidth > 1200
                                        ? 3
                                        : constraints.maxWidth > 700
                                        ? 2
                                        : 1;
                                    double cardWidth = (constraints.maxWidth / columns) - (16.0 * (columns - 1) / columns);

                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: entry.value.map((cardapio) {
                                        return Container(
                                          width: cardWidth,
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Cores.cardBlack,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Cores.borderGray),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cardapio.nome, style: TextStyle(color: Cores.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                                              SizedBox(height: 8),
                                              Text(cardapio.descricao, style: TextStyle(color: Cores.textGray)),
                                              SizedBox(height: 8),
                                              Text('R\$ ${cardapio.preco.toStringAsFixed(2)}', style: TextStyle(color: Cores.textWhite)),
                                              SizedBox(height: 8),
                                              Text(cardapio.ativo ? 'Ativo' : 'Suspenso', style: TextStyle(color: cardapio.ativo ? Colors.green : Colors.red)),
                                              SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  IconButton(icon: Icon(Icons.edit, color: Cores.lightRed), onPressed: () => _mostrarDialogEditarItem(cardapio)),
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