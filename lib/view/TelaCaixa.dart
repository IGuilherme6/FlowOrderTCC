import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auxiliar/Cores.dart';
import '../controller/PedidoController.dart';
import '../controller/MesaController.dart';
import '../controller/CardapioController.dart';
import '../models/Pedido.dart';
import '../models/Mesa.dart';
import '../models/Cardapio.dart';
import '../models/ItemCardapio.dart';
import 'BarraLateral.dart';

/// ===================================
/// TELA PRINCIPAL DO CAIXA
/// ===================================
class TelaCaixa extends StatefulWidget {
  @override
  State<TelaCaixa> createState() => _TelaCaixaState();
}

class _TelaCaixaState extends State<TelaCaixa> {
  final PedidoController _pedidoController = PedidoController();
  String _filtroStatus = 'Todos';
  Future<Stream<List<Pedido>>>? _pedidosFuture;

  @override
  void initState() {
    super.initState();
    _pedidosFuture = _pedidoController.listarPedidosTempoReal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/caixa'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildPedidosArea()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdicionarPedidoDialog,
        backgroundColor: Cores.primaryRed,
        icon: Icon(Icons.add, color: Cores.textWhite),
        label: Text('Novo Pedido', style: TextStyle(color: Cores.textWhite)),
      ),
    );
  }

  // -------------------------
  // Header
  // -------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Caixa',
            style: TextStyle(
                color: Cores.textWhite,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Cores.cardBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Cores.borderGray)),
          child: Row(
            children: [
              Icon(Icons.restaurant_menu, color: Cores.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text('Sistema de Pedidos',
                  style: TextStyle(color: Cores.textGray, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------
  // Filtros
  // -------------------------
  Widget _buildFiltros() {
    final filtros = ['Todos', ...Pedido.statusOpcoes.where((s) => s != 'Cancelado')];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final isSelected = _filtroStatus == filtro;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filtro),
              selected: isSelected,
              onSelected: (_) => setState(() => _filtroStatus = filtro),
              backgroundColor: Cores.cardBlack,
              selectedColor: Cores.primaryRed,
              labelStyle: TextStyle(
                  color: isSelected ? Cores.textWhite : Cores.textGray),
              side: BorderSide(color: Cores.borderGray),
            ),
          );
        },
      ),
    );
  }

  // -------------------------
  // Área de pedidos
  // -------------------------
  Widget _buildPedidosArea() {
    return FutureBuilder<Stream<List<Pedido>>>(
      future: _pedidosFuture,
      builder: (context, futureSnap) {
        if (futureSnap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Cores.primaryRed)));
        }
        if (futureSnap.hasError) {
          return Center(
              child: Text("Erro: ${futureSnap.error}",
                  style: TextStyle(color: Cores.textGray)));
        }
        if (!futureSnap.hasData) return _buildEmptyState();

        return StreamBuilder<List<Pedido>>(
          stream: futureSnap.data,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Cores.primaryRed)));
            }
            if (snap.hasError) {
              return Center(
                  child: Text("Erro: ${snap.error}",
                      style: TextStyle(color: Cores.textGray)));
            }
            if (!snap.hasData || snap.data!.isEmpty) return _buildEmptyState();

            final pedidos = _filtrarPedidos(snap.data!);
            if (pedidos.isEmpty) return _buildEmptyState();

            return ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, i) => _buildPedidoCard(pedidos[i]),
            );
          },
        );
      },
    );
  }

  // -------------------------
  // Empty state
  // -------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Cores.textGray),
          const SizedBox(height: 16),
          Text('Nenhum pedido encontrado',
              style: TextStyle(color: Cores.textGray, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Clique no botão "+" para criar um novo pedido',
              style: TextStyle(color: Cores.textGray, fontSize: 14)),
        ],
      ),
    );
  }

  // -------------------------
  // Pedido Card
  // -------------------------

  Widget _buildPedidoCard(Pedido pedido) {
    final total = pedido.calcularTotal();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Cores.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Cores.borderGray)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Cores.primaryRed,
                  borderRadius: BorderRadius.circular(16)),
              child: Text(
                'Mesa ${pedido.mesa.numero}'
                    '${pedido.mesa.nome.isNotEmpty ? ' - ${pedido.mesa.nome}' : ''}',
                style: TextStyle(
                    color: Cores.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Total: R\$ ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            _buildStatusChip(pedido.statusAtual),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
              'Horário: ${_formatarHorario(pedido.horario)} - ${pedido.itens.length} itens',
              style: TextStyle(color: Cores.textGray, fontSize: 12)),
        ),
        iconColor: Cores.textWhite,
        collapsedIconColor: Cores.textGray,
        children: [
          // Observação do pedido
          if (pedido.observacao != null && pedido.observacao!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Cores.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Cores.primaryRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Observação do Pedido:',
                      style: TextStyle(
                          color: Cores.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(pedido.observacao!,
                      style: TextStyle(color: Cores.textWhite, fontSize: 13)),
                ],
              ),
            ),
          ],

          // Lista de itens
          ...pedido.itens.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Cores.borderGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${item.quantidade}x ${item.nome}',
                          style: TextStyle(
                              color: Cores.textWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text(
                        'R\$ ${(item.preco * item.quantidade).toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Cores.primaryRed,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${item.categoria}',
                    style: TextStyle(color: Cores.textGray, fontSize: 12)),

                // Observação do item
                if (item.observacao != null && item.observacao!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Cores.textGray.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                        'Obs: ${item.observacao}',
                        style: TextStyle(
                            color: Cores.textGray,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ],
            ),
          )),

          const SizedBox(height: 16),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.edit, size: 16, color: Cores.textWhite),
                  label: Text('Editar', style: TextStyle(color: Cores.textWhite)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Cores.borderGray),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (pedido.statusAtual != "Aberto") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Só é possível editar pedidos em aberto."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final atualizado = await showDialog(
                      context: context,
                      builder: (_) => EditarPedidoDialog(pedido: pedido),
                    );

                    if (atualizado == true) {
                      setState(() {}); // força recarregar a lista
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.delete, size: 16, color: Colors.red),
                  label: Text('Cancelar', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (pedido.statusAtual != "Aberto") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Só é possível Cancelar pedidos em aberto. Cumunique a cozinha"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Cancelar Pedido"),
                        content: Text(
                            "Tem certeza que deseja Cancelar este pedido da mesa ${pedido.mesa.numero}?"),
                        actions: [
                          TextButton(
                            child: Text("Cancelar"),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          ElevatedButton(
                            child: Text("Excluir"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      final sucesso = await _pedidoController.excluirPedido(pedido);
                      if (sucesso) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Pedido excluído com sucesso."),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // força atualizar a lista
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erro ao excluir pedido."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.payment, size: 16, color: Cores.textWhite),
                  label: Text('Pagar', style: TextStyle(color: Cores.textWhite)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _abrirDialogPagamento(pedido),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _abrirDialogPagamento(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => PagamentoDialog(pedido: pedido),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Em Preparo':
        color = Colors.orange;
        break;
      case 'Pronto':
        color = Colors.green;
        break;
      case 'Aberto':
        color = Colors.blue;
        break;
      default:
        color = Cores.textGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // -------------------------
  // Helpers
  // -------------------------
  List<Pedido> _filtrarPedidos(List<Pedido> pedidos) {
    if (_filtroStatus == 'Todos') return pedidos;
    return pedidos.where((p) => p.statusAtual == _filtroStatus).toList();
  }

  void _showAdicionarPedidoDialog() {
    showDialog(
        context: context, builder: (_) => AdicionarPedidoDialog());
  }

  String _formatarHorario(DateTime horario) {
    return '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
  }
}

/// ===================================
/// DIÁLOGO PARA ADICIONAR PEDIDO
/// ===================================
class AdicionarPedidoDialog extends StatefulWidget {
  @override
  State<AdicionarPedidoDialog> createState() => _AdicionarPedidoDialogState();
}

class _AdicionarPedidoDialogState extends State<AdicionarPedidoDialog> {
  final PedidoController _pedidoController = PedidoController();
  final MesaController _mesaController = MesaController();
  final CardapioController _cardapioController = CardapioController();

  Mesa? mesaSelecionada;
  List<Mesa> mesas = [];
  List<Cardapio> cardapio = [];
  List<ItemCardapio> itensSelecionados = [];
  final obsController = TextEditingController();
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final m = await _mesaController.buscarMesas();
    final c = await _cardapioController.buscarCardapios();
    setState(() {
      mesas = m;
      cardapio = c.where((i) => i.ativo).toList();
      carregando = false;
    });
  }

  void _customizarItem(Cardapio item) {
    showDialog(
      context: context,
      builder: (_) => CustomizarItemDialog(
        item: item,
        onConfirm: (novoItem) {
          setState(() => itensSelecionados.add(novoItem));
        },
      ),
    );
  }

  Future<void> _salvar() async {
    if (mesaSelecionada == null || itensSelecionados.isEmpty) return;
    final pedido = Pedido(
      horario: DateTime.now(),
      mesa: mesaSelecionada!,
      itens: itensSelecionados,
      statusAtual: "Aberto",
      observacao: obsController.text,
    );
    await _pedidoController.cadastrarPedido(pedido);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Cores.cardBlack,
      title: Text("Novo Pedido",
          style: TextStyle(color: Cores.textWhite, fontSize: 20)),
      content: carregando
          ? Center(child: CircularProgressIndicator())
          : SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: mesas.map((m) {
                final selected = mesaSelecionada?.uid == m.uid;
                return ChoiceChip(
                  label: Text("Mesa ${m.numero}"),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => mesaSelecionada = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: cardapio.length,
                itemBuilder: (_, i) {
                  final item = cardapio[i];
                  return Card(
                    color: Cores.cardBlack,
                    child: ListTile(
                      title: Text(item.nome,
                          style: TextStyle(color: Cores.textWhite)),
                      subtitle: Text(
                          "R\$ ${item.preco.toStringAsFixed(2)} - ${item.categoria}",
                          style: TextStyle(color: Cores.textGray)),
                      trailing: IconButton(
                        icon: Icon(Icons.add, color: Cores.primaryRed),
                        onPressed: () => _customizarItem(item),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (itensSelecionados.isNotEmpty) ...[
              Divider(color: Cores.borderGray),
              Text("Resumo",
                  style: TextStyle(color: Cores.textWhite)),
              ...itensSelecionados.map((i) => Text(
                  "${i.nome} - R\$ ${i.preco.toStringAsFixed(2)}",
                  style: TextStyle(color: Cores.textGray))),
              TextField(
                controller: obsController,
                decoration: InputDecoration(
                  hintText: "Observação do pedido...",
                ),
              )
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
            child: Text("Cancelar", style: TextStyle(color: Cores.textGray)),
            onPressed: () => Navigator.pop(context)),
        ElevatedButton(
            child: Text("Salvar"),
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
                backgroundColor: Cores.primaryRed)),
      ],
    );
  }
}

/// ===================================
/// DIÁLOGO PARA CUSTOMIZAR ITEM
/// ===================================
class CustomizarItemDialog extends StatefulWidget {
  final Cardapio item;
  final Function(ItemCardapio) onConfirm;
  CustomizarItemDialog({required this.item, required this.onConfirm});

  @override
  State<CustomizarItemDialog> createState() => _CustomizarItemDialogState();
}

class _CustomizarItemDialogState extends State<CustomizarItemDialog> {
  final observacaoController = TextEditingController();
  final precoController = TextEditingController();
  int quantidade = 1;
  bool usarPrecoCustomizado = false;

  @override
  void initState() {
    super.initState();
    precoController.text = widget.item.preco.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Cores.cardBlack,
      title: Text("Customizar item",
          style: TextStyle(color: Cores.textWhite)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: observacaoController,
            decoration: InputDecoration(
                hintText: "Observações (ex: sem cebola, extra queijo...)",
                hintStyle: TextStyle(color: Cores.textGray)),
          ),
          Row(
            children: [
              Checkbox(
                  value: usarPrecoCustomizado,
                  onChanged: (v) =>
                      setState(() => usarPrecoCustomizado = v!)),
              Text("Usar preço customizado",
                  style: TextStyle(color: Cores.textWhite)),
            ],
          ),
          if (usarPrecoCustomizado)
            TextField(
              controller: precoController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Preço"),
            ),
          Row(
            children: [
              IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () =>
                      setState(() => quantidade = quantidade > 1 ? quantidade - 1 : 1)),
              Text("$quantidade",
                  style: TextStyle(color: Cores.textWhite)),
              IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => setState(() => quantidade++)),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          child: Text("Adicionar"),
          onPressed: () {
            final preco = usarPrecoCustomizado
                ? double.tryParse(precoController.text) ??
                widget.item.preco
                : widget.item.preco;
            final novoItem = ItemCardapio(
              uid: widget.item.uid,
              nome: widget.item.nome,
              preco: preco,
              categoria: widget.item.categoria,
              observacao: observacaoController.text,
              quantidade: quantidade,
            );
            widget.onConfirm(novoItem);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class PagamentoDialog extends StatefulWidget {
  final Pedido pedido;

  const PagamentoDialog({Key? key, required this.pedido}) : super(key: key);

  @override
  State<PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<PagamentoDialog> {
  String metodoPagamento = 'Dinheiro';
  final valorPagoController = TextEditingController();
  final descontoController = TextEditingController();
  double desconto = 0.0;
  bool aplicandoDesconto = false;

  late double totalOriginal;
  double get totalComDesconto => totalOriginal - desconto;
  double get troco => (double.tryParse(valorPagoController.text) ?? 0) - totalComDesconto;

  @override
  void initState() {
    super.initState();
    totalOriginal = widget.pedido.calcularTotal();
    valorPagoController.text = totalOriginal.toStringAsFixed(2);

    // Listener para calcular desconto
    descontoController.addListener(() {
      setState(() {
        desconto = double.tryParse(descontoController.text) ?? 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Cores.cardBlack,
      title: Row(
        children: [
          Icon(Icons.payment, color: Cores.primaryRed),
          const SizedBox(width: 8),
          Text(
            'Pagamento - Mesa ${widget.pedido.mesa.numero}',
            style: TextStyle(color: Cores.textWhite, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do pedido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Cores.borderGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total original:',
                          style: TextStyle(color: Cores.textGray)),
                      Text('R\$ ${totalOriginal.toStringAsFixed(2)}',
                          style: TextStyle(color: Cores.textWhite)),
                    ],
                  ),
                  if (desconto > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Desconto:',
                            style: TextStyle(color: Cores.textGray)),
                        Text('- R\$ ${desconto.toStringAsFixed(2)}',
                            style: TextStyle(color: Cores.primaryRed)),
                      ],
                    ),
                  ],
                  const Divider(color: Cores.borderGray),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total a pagar:',
                          style: TextStyle(
                              color: Cores.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('R\$ ${totalComDesconto.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Cores.primaryRed,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Método de pagamento
            Text('Método de pagamento:',
                style: TextStyle(color: Cores.textWhite, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Dinheiro', 'Cartão', 'PIX'].map((metodo) {
                final selected = metodoPagamento == metodo;
                return ChoiceChip(
                  label: Text(metodo),
                  selected: selected,
                  selectedColor: Cores.primaryRed,
                  onSelected: (value) {
                    setState(() {
                      metodoPagamento = metodo;
                      if (metodo != 'Dinheiro') {
                        valorPagoController.text = totalComDesconto.toStringAsFixed(2);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Desconto
            Row(
              children: [
                Checkbox(
                  value: aplicandoDesconto,
                  onChanged: (value) {
                    setState(() {
                      aplicandoDesconto = value!;
                      if (!aplicandoDesconto) {
                        descontoController.clear();
                        desconto = 0.0;
                      }
                    });
                  },
                ),
                Text('Aplicar desconto',
                    style: TextStyle(color: Cores.textWhite)),
              ],
            ),

            if (aplicandoDesconto) ...[
              TextField(
                controller: descontoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Cores.textWhite),
                decoration: InputDecoration(
                  labelText: 'Valor do desconto (R\$)',
                  labelStyle: TextStyle(color: Cores.textGray),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Cores.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Cores.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Valor pago (só para dinheiro)
            if (metodoPagamento == 'Dinheiro') ...[
              TextField(
                controller: valorPagoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Cores.textWhite),
                decoration: InputDecoration(
                  labelText: 'Valor pago (R\$)',
                  labelStyle: TextStyle(color: Cores.textGray),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Cores.borderGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Cores.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (troco > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Troco:', style: TextStyle(color: Colors.green)),
                      Text('R\$ ${troco.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: Cores.textGray)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Cores.primaryRed,
          ),
          child: Text('Confirmar Pagamento',
              style: TextStyle(color: Cores.textWhite)),
          onPressed: _confirmarPagamento,
        ),
      ],
    );
  }

  void _confirmarPagamento() async {
    // Validações
    if (metodoPagamento == 'Dinheiro') {
      final valorPago = double.tryParse(valorPagoController.text) ?? 0;
      if (valorPago < totalComDesconto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valor pago insuficiente!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Cores.cardBlack,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Cores.primaryRed),
            const SizedBox(width: 16),
            Text('Processando pagamento...',
                style: TextStyle(color: Cores.textWhite)),
          ],
        ),
      ),
    );

    try {
      final pedidoController = PedidoController(); // Instanciar o controller
      final valorPago = double.tryParse(valorPagoController.text) ?? totalComDesconto;

      final sucesso = await pedidoController.processarPagamento(
        pedidoUid: widget.pedido.uid!,
        metodoPagamento: metodoPagamento,
        valorPago: valorPago,
        desconto: desconto,
        troco: metodoPagamento == 'Dinheiro' ? troco : null,
      );

      // Fechar loading
      Navigator.pop(context);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Pagamento processado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Fechar o diálogo e atualizar a lista de pedidos
        Navigator.pop(context, true); // Retorna true para indicar que houve pagamento
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar pagamento. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class EditarPedidoDialog extends StatefulWidget {
  final Pedido pedido;
  EditarPedidoDialog({required this.pedido});

  @override
  State<EditarPedidoDialog> createState() => _EditarPedidoDialogState();
}

class _EditarPedidoDialogState extends State<EditarPedidoDialog> {
  final PedidoController _pedidoController = PedidoController();
  final CardapioController _cardapioController = CardapioController();
  List<Cardapio> cardapio = [];
  late Mesa mesaSelecionada;
  late List<ItemCardapio> itensSelecionados;
  late TextEditingController obsController;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    mesaSelecionada = widget.pedido.mesa;
    itensSelecionados = List.from(widget.pedido.itens);
    obsController = TextEditingController(text: widget.pedido.observacao ?? "");
    _carregarCardapio();
  }

  Future<void> _carregarCardapio() async {
    final c = await _cardapioController.buscarCardapios();
    setState(() {
      cardapio = c.where((i) => i.ativo).toList();
      carregando = false;
    });
  }

  void _customizarItem(Cardapio item) {
    showDialog(
      context: context,
      builder: (_) => CustomizarItemDialog(
        item: item,
        onConfirm: (novoItem) {
          setState(() => itensSelecionados.add(novoItem));
        },
      ),
    );
  }

  void _removerItem(ItemCardapio item) {
    setState(() {
      itensSelecionados.remove(item);
    });
  }

  Future<void> _salvar() async {
    final pedidoEditado = Pedido(
      uid: widget.pedido.uid,
      horario: widget.pedido.horario,
      mesa: mesaSelecionada,
      itens: itensSelecionados,
      statusAtual: widget.pedido.statusAtual,
      observacao: obsController.text,
      gerenteUid: widget.pedido.gerenteUid, // mantém gerenteUid
    );

    final sucesso = await _pedidoController.editarPedido(pedidoEditado);
    if (sucesso) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Cores.cardBlack,
      title: Text("Editar Pedido", style: TextStyle(color: Cores.textWhite)),
      content: carregando
          ? Center(child: CircularProgressIndicator())
          : SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cardapio.length,
                itemBuilder: (_, i) {
                  final item = cardapio[i];
                  return Card(
                    color: Cores.cardBlack,
                    child: ListTile(
                      title: Text(item.nome,
                          style: TextStyle(color: Cores.textWhite)),
                      subtitle: Text(
                        "R\$ ${item.preco.toStringAsFixed(2)} - ${item.categoria}",
                        style: TextStyle(color: Cores.textGray),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add, color: Cores.primaryRed),
                        onPressed: () => _customizarItem(item),
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(color: Cores.borderGray),
            Text("Itens do Pedido",
                style: TextStyle(color: Cores.textWhite)),
            ...itensSelecionados.map(
                  (i) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Cores.borderGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${i.quantidade}x ${i.nome} - R\$ ${(i.preco * i.quantidade).toStringAsFixed(2)}",
                        style: TextStyle(color: Cores.textGray),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removerItem(i),
                    ),
                  ],
                ),
              ),
            ),
            TextField(
              controller: obsController,
              decoration: InputDecoration(
                hintText: "Observação do pedido...",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            child: Text("Cancelar",
                style: TextStyle(color: Cores.textGray)),
            onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          child: Text("Salvar"),
          onPressed: _salvar,
          style: ElevatedButton.styleFrom(backgroundColor: Cores.primaryRed),
        ),
      ],
    );
  }
}
