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
import 'package:flutter/gestures.dart';
import '../models/GlobalUser.dart';

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
                            child: Text("sair"),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          ElevatedButton(
                            child: Text("Cancelar Pedido"),
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

class _AdicionarPedidoDialogState extends State<AdicionarPedidoDialog>
    with TickerProviderStateMixin {
  final PedidoController _pedidoController = PedidoController();
  final MesaController _mesaController = MesaController();
  final CardapioController _cardapioController = CardapioController();

  Mesa? mesaSelecionada;
  List<Mesa> mesas = [];
  List<Cardapio> cardapio = [];
  List<ItemCardapio> itensSelecionados = [];
  final obsController = TextEditingController();
  bool carregando = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _carregar();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    obsController.dispose();
    super.dispose();
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

  void _removerItem(int index) {
    setState(() {
      itensSelecionados.removeAt(index);
    });
  }

  double get _totalPedido {
    return itensSelecionados.fold(0.0, (sum, item) => sum + item.preco);
  }

  Future<void> _salvar() async {
    if (mesaSelecionada == null || itensSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione uma mesa e pelo menos um item'),
          backgroundColor: Cores.primaryRed,
        ),
      );
      return;
    }

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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Cores.cardBlack,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Cores.primaryRed, Cores.primaryRed.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Novo Pedido",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Selecione a mesa e adicione os itens",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: carregando
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Cores.primaryRed),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Carregando...",
                          style: TextStyle(color: Cores.textGray),
                        ),
                      ],
                    ),
                  )
                      : Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel - Menu
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mesa Selection
                              Text(
                                "Selecione a Mesa",
                                style: TextStyle(
                                  color: Cores.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                height: 60,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context).copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                      },
                                      scrollbars: true,
                                    ),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: mesas.length,
                                      itemBuilder: (context, index) {
                                        final mesa = mesas[index];
                                        final selected = mesaSelecionada?.uid == mesa.uid;
                                        return Container(
                                          margin: EdgeInsets.only(right: 8),
                                          child: GestureDetector(
                                            onTap: () => setState(() => mesaSelecionada = mesa),
                                            child: AnimatedContainer(
                                              duration: Duration(milliseconds: 200),
                                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              decoration: BoxDecoration(
                                                color: selected ? Cores.primaryRed : Cores.cardBlack,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: selected ? Cores.primaryRed : Cores.borderGray,
                                                  width: 2,
                                                ),
                                                boxShadow: selected ? [
                                                  BoxShadow(
                                                    color: Cores.primaryRed.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ] : [],
                                              ),
                                              child: Text(
                                                "Mesa ${mesa.numero}",
                                                style: TextStyle(
                                                  color: selected ? Colors.white : Cores.textWhite,
                                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 24),

                              // Cardápio
                              Text(
                                "Cardápio",
                                style: TextStyle(
                                  color: Cores.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),

                              Expanded(
                                child: ListView.builder(
                                  itemCount: cardapio.length,
                                  itemBuilder: (context, index) {
                                    final item = cardapio[index];
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: Card(
                                        color: Cores.cardBlack,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Cores.borderGray.withOpacity(0.3)),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Cores.primaryRed.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.restaurant,
                                                  color: Cores.primaryRed,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.nome,
                                                      style: TextStyle(
                                                        color: Cores.textWhite,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Cores.primaryRed.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            item.categoria,
                                                            style: TextStyle(
                                                              color: Cores.primaryRed,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          "R\$ ${item.preco.toStringAsFixed(2)}",
                                                          style: TextStyle(
                                                            color: Cores.textGray,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Cores.primaryRed,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(Icons.add, color: Colors.white),
                                                  onPressed: () => _customizarItem(item),
                                                  style: IconButton.styleFrom(
                                                    padding: EdgeInsets.all(8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 24),

                        // Right Panel - Resumo
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Cores.cardBlack.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.receipt_long, color: Cores.primaryRed),
                                    SizedBox(width: 8),
                                    Text(
                                      "Resumo do Pedido",
                                      style: TextStyle(
                                        color: Cores.textWhite,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                if (itensSelecionados.isEmpty)
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Cores.borderGray.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Cores.textGray,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Nenhum item selecionado",
                                          style: TextStyle(
                                            color: Cores.textGray,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: itensSelecionados.length,
                                            itemBuilder: (context, index) {
                                              final item = itensSelecionados[index];
                                              return Container(
                                                margin: EdgeInsets.only(bottom: 8),
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Cores.cardBlack,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item.nome,
                                                            style: TextStyle(
                                                              color: Cores.textWhite,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            "R\$ ${item.preco.toStringAsFixed(2)}",
                                                            style: TextStyle(
                                                              color: Cores.primaryRed,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.remove_circle_outline, color: Cores.primaryRed),
                                                      onPressed: () => _removerItem(index),
                                                      style: IconButton.styleFrom(
                                                        padding: EdgeInsets.all(4),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Cores.primaryRed.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Cores.primaryRed.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total:",
                                                style: TextStyle(
                                                  color: Cores.textWhite,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "R\$ ${_totalPedido.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color: Cores.primaryRed,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                SizedBox(height: 16),

                                // Observação
                                TextField(
                                  controller: obsController,
                                  maxLines: 3,
                                  style: TextStyle(color: Cores.textWhite),
                                  decoration: InputDecoration(
                                    hintText: "Observação do pedido...",
                                    hintStyle: TextStyle(color: Cores.textGray),
                                    filled: true,
                                    fillColor: Cores.cardBlack,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Cores.borderGray),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Cores.borderGray),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Cores.primaryRed),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Cores.cardBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Cores.borderGray.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            color: Cores.textGray,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Cores.primaryRed,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              "Salvar Pedido",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

class _CustomizarItemDialogState extends State<CustomizarItemDialog>
    with TickerProviderStateMixin {
  final observacaoController = TextEditingController();
  final precoController = TextEditingController();
  int quantidade = 1;
  bool usarPrecoCustomizado = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    precoController.text = widget.item.preco.toStringAsFixed(2);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    observacaoController.dispose();
    precoController.dispose();
    super.dispose();
  }

  double get _precoTotal {
    final precoUnitario = usarPrecoCustomizado
        ? (double.tryParse(precoController.text) ?? widget.item.preco)
        : widget.item.preco;
    return precoUnitario * quantidade;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Cores.cardBlack,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Cores.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_note,
                        color: Cores.primaryRed,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customizar Item",
                            style: TextStyle(
                              color: Cores.textWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.item.nome,
                            style: TextStyle(
                              color: Cores.textGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Cores.textGray),
                      style: IconButton.styleFrom(
                        backgroundColor: Cores.borderGray.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Item Info Card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Cores.borderGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Cores.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: Cores.primaryRed,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.nome,
                              style: TextStyle(
                                color: Cores.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.item.categoria,
                              style: TextStyle(
                                color: Cores.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "R\$ ${widget.item.preco.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Cores.primaryRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Quantidade
                Text(
                  "Quantidade",
                  style: TextStyle(
                    color: Cores.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Cores.cardBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Cores.borderGray),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: quantidade > 1 ? Cores.primaryRed : Cores.borderGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.remove, color: Colors.white),
                          onPressed: quantidade > 1
                              ? () => setState(() => quantidade--)
                              : null,
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        child: Text(
                          "$quantidade",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Cores.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Cores.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: Colors.white),
                          onPressed: () => setState(() => quantidade++),
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Preço Customizado
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: usarPrecoCustomizado,
                        onChanged: (v) => setState(() => usarPrecoCustomizado = v!),
                        activeColor: Cores.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Usar preço customizado",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (usarPrecoCustomizado) ...[
                  SizedBox(height: 12),
                  TextField(
                    controller: precoController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: Cores.textWhite),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "Preço customizado (R\$)",
                      labelStyle: TextStyle(color: Cores.textGray),
                      prefixIcon: Icon(Icons.attach_money, color: Cores.primaryRed),
                      filled: true,
                      fillColor: Cores.cardBlack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Cores.borderGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Cores.borderGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Cores.primaryRed, width: 2),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 20),

                // Observações
                Text(
                  "Observações",
                  style: TextStyle(
                    color: Cores.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: observacaoController,
                  maxLines: 3,
                  style: TextStyle(color: Cores.textWhite),
                  decoration: InputDecoration(
                    hintText: "Ex: sem cebola, extra queijo, ponto da carne...",
                    hintStyle: TextStyle(color: Cores.textGray),
                    prefixIcon: Icon(Icons.note_add, color: Cores.primaryRed),
                    filled: true,
                    fillColor: Cores.cardBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Cores.borderGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Cores.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Cores.primaryRed, width: 2),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Total
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Cores.primaryRed.withOpacity(0.1),
                        Cores.primaryRed.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Cores.primaryRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total do item:",
                        style: TextStyle(
                          color: Cores.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "R\$ ${_precoTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Cores.primaryRed,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        "Cancelar",
                        style: TextStyle(
                          color: Cores.textGray,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final preco = usarPrecoCustomizado
                            ? double.tryParse(precoController.text) ?? widget.item.preco
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Cores.primaryRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart),
                          SizedBox(width: 8),
                          Text(
                            "Adicionar",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PagamentoDialog extends StatefulWidget {
  final Pedido pedido;

  const PagamentoDialog({Key? key, required this.pedido}) : super(key: key);

  @override
  State<PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<PagamentoDialog>
    with TickerProviderStateMixin {
  String metodoPagamento = 'Dinheiro';
  final valorPagoController = TextEditingController();
  final descontoController = TextEditingController();
  double desconto = 0.0;
  bool aplicandoDesconto = false;

  late double totalOriginal;
  double get totalComDesconto => totalOriginal - desconto;
  double get troco => (double.tryParse(valorPagoController.text) ?? 0) - totalComDesconto;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    totalOriginal = widget.pedido.calcularTotal();
    valorPagoController.text = totalOriginal.toStringAsFixed(2);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    descontoController.addListener(() {
      setState(() {
        desconto = double.tryParse(descontoController.text) ?? 0.0;
      });
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    valorPagoController.dispose();
    descontoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Container(
                width: 500,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                decoration: BoxDecoration(
                  color: Cores.cardBlack,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pagamento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Mesa ${widget.pedido.mesa.numero}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Resumo do pedido
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Cores.borderGray.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        'Resumo do Pedido',
                                        style: TextStyle(
                                          color: Cores.textWhite,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total original:', style: TextStyle(color: Cores.textGray)),
                                      Text('R\$ ${totalOriginal.toStringAsFixed(2)}',
                                          style: TextStyle(color: Cores.textWhite)),
                                    ],
                                  ),
                                  if (desconto > 0) ...[
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Desconto:', style: TextStyle(color: Cores.textGray)),
                                        Text('- R\$ ${desconto.toStringAsFixed(2)}',
                                            style: TextStyle(color: Cores.primaryRed)),
                                      ],
                                    ),
                                  ],
                                  Divider(color: Cores.borderGray, height: 24),
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
                                              color: Colors.green,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // Método de pagamento
                            Text('Método de pagamento:',
                                style: TextStyle(
                                    color: Cores.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 12),
                            Row(
                              children: ['Dinheiro', 'Cartão', 'PIX'].map((metodo) {
                                final selected = metodoPagamento == metodo;
                                IconData icon;
                                switch (metodo) {
                                  case 'Dinheiro':
                                    icon = Icons.attach_money;
                                    break;
                                  case 'Cartão':
                                    icon = Icons.credit_card;
                                    break;
                                  case 'PIX':
                                    icon = Icons.qr_code;
                                    break;
                                  default:
                                    icon = Icons.payment;
                                }
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(right: metodo != 'PIX' ? 8 : 0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          metodoPagamento = metodo;
                                          if (metodo != 'Dinheiro') {
                                            valorPagoController.text = totalComDesconto.toStringAsFixed(2);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: selected ? Colors.green : Cores.cardBlack,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selected ? Colors.green : Cores.borderGray,
                                            width: 2,
                                          ),
                                          boxShadow: selected ? [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ] : [],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              icon,
                                              color: selected ? Colors.white : Cores.textGray,
                                              size: 24,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              metodo,
                                              style: TextStyle(
                                                color: selected ? Colors.white : Cores.textWhite,
                                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 24),

                            // Desconto
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
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
                                    activeColor: Cores.primaryRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Aplicar desconto',
                                  style: TextStyle(
                                    color: Cores.textWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            if (aplicandoDesconto) ...[
                              SizedBox(height: 12),
                              TextField(
                                controller: descontoController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: Cores.textWhite),
                                decoration: InputDecoration(
                                  labelText: 'Valor do desconto (R\$)',
                                  labelStyle: TextStyle(color: Cores.textGray),
                                  prefixIcon: Icon(Icons.local_offer, color: Cores.primaryRed),
                                  filled: true,
                                  fillColor: Cores.cardBlack,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Cores.borderGray),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Cores.borderGray),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Cores.primaryRed, width: 2),
                                  ),
                                ),
                              ),
                            ],

                            // Valor pago (só para dinheiro)
                            if (metodoPagamento == 'Dinheiro') ...[
                              SizedBox(height: 16),
                              TextField(
                                controller: valorPagoController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: Cores.textWhite),
                                decoration: InputDecoration(
                                  labelText: 'Valor recebido (R\$)',
                                  labelStyle: TextStyle(color: Cores.textGray),
                                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                                  filled: true,
                                  fillColor: Cores.cardBlack,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Cores.borderGray),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Cores.borderGray),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green, width: 2),
                                  ),
                                ),
                              ),
                              if (troco > 0) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.withOpacity(0.1),
                                        Colors.green.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.monetization_on, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Troco:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Text('R\$ ${troco.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Footer
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Cores.cardBlack.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(color: Cores.borderGray.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Cores.textGray,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _confirmarPagamento,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle),
                                SizedBox(width: 8),
                                Text(
                                  'Confirmar Pagamento',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmarPagamento() async {
    // Validações
    if (metodoPagamento == 'Dinheiro') {
      final valorPago = double.tryParse(valorPagoController.text) ?? 0;
      if (valorPago < totalComDesconto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Valor pago insuficiente!'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Cores.cardBlack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Processando pagamento...',
                  style: TextStyle(color: Cores.textWhite)),
            ],
          ),
        ),
      ),
    );

    try {
      final pedidoController = PedidoController();
      final valorPago = double.tryParse(valorPagoController.text) ?? totalComDesconto;

      final sucesso = await pedidoController.processarPagamento(
        pedidoUid: widget.pedido.uid!,
        metodoPagamento: metodoPagamento,
        valorPago: valorPago,
        desconto: desconto,
        troco: metodoPagamento == 'Dinheiro' ? troco : null,
      );

      Navigator.pop(context); // Fechar loading

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Pagamento processado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao processar pagamento. Tente novamente.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fechar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Erro: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

class _EditarPedidoDialogState extends State<EditarPedidoDialog>
    with TickerProviderStateMixin {
  final PedidoController _pedidoController = PedidoController();
  final CardapioController _cardapioController = CardapioController();
  List<Cardapio> cardapio = [];
  late Mesa mesaSelecionada;
  late List<ItemCardapio> itensSelecionados;
  late TextEditingController obsController;
  bool carregando = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    mesaSelecionada = widget.pedido.mesa;
    itensSelecionados = List.from(widget.pedido.itens);
    obsController = TextEditingController(text: widget.pedido.observacao ?? "");

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _carregarCardapio();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    obsController.dispose();
    super.dispose();
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

  double get _totalPedido {
    return itensSelecionados.fold(0.0, (sum, item) => sum + (item.preco * item.quantidade));
  }

  Future<void> _salvar() async {
    if (itensSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('O pedido deve ter pelo menos um item'),
          backgroundColor: Cores.primaryRed,
        ),
      );
      return;
    }

    final pedidoEditado = Pedido(
      uid: widget.pedido.uid,
      horario: widget.pedido.horario,
      mesa: mesaSelecionada,
      itens: itensSelecionados,
      statusAtual: widget.pedido.statusAtual,
      observacao: obsController.text,
      gerenteUid: widget.pedido.gerenteUid,
    );

    final sucesso = await _pedidoController.editarPedido(pedidoEditado);
    if (sucesso) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: 900,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Cores.cardBlack,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Editar Pedido",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Mesa ${widget.pedido.mesa.numero} - ${widget.pedido.statusAtual}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: carregando
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Carregando cardápio...",
                          style: TextStyle(color: Cores.textGray),
                        ),
                      ],
                    ),
                  )
                      : Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel - Cardápio
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Adicionar Itens",
                                style: TextStyle(
                                  color: Cores.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: cardapio.length,
                                  itemBuilder: (context, index) {
                                    final item = cardapio[index];
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: Card(
                                        color: Cores.cardBlack,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Cores.borderGray.withOpacity(0.3)),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.restaurant,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.nome,
                                                      style: TextStyle(
                                                        color: Cores.textWhite,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            item.categoria,
                                                            style: TextStyle(
                                                              color: Colors.orange,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          "R\$ ${item.preco.toStringAsFixed(2)}",
                                                          style: TextStyle(
                                                            color: Cores.textGray,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(Icons.add, color: Colors.white),
                                                  onPressed: () => _customizarItem(item),
                                                  style: IconButton.styleFrom(
                                                    padding: EdgeInsets.all(8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 24),

                        // Right Panel - Itens do Pedido
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Cores.cardBlack.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_cart, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(
                                      "Itens do Pedido",
                                      style: TextStyle(
                                        color: Cores.textWhite,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                if (itensSelecionados.isEmpty)
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Cores.borderGray.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart_outlined,
                                            color: Cores.textGray,
                                            size: 48,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Nenhum item no pedido",
                                            style: TextStyle(
                                              color: Cores.textGray,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: itensSelecionados.length,
                                            itemBuilder: (context, index) {
                                              final item = itensSelecionados[index];
                                              return Container(
                                                margin: EdgeInsets.only(bottom: 8),
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Cores.cardBlack,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "${item.quantidade}x ${item.nome}",
                                                            style: TextStyle(
                                                              color: Cores.textWhite,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          if (item.observacao?.isNotEmpty == true)
                                                            Text(
                                                              item.observacao!,
                                                              style: TextStyle(
                                                                color: Cores.textGray,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          Text(
                                                            "R\$ ${(item.preco * item.quantidade).toStringAsFixed(2)}",
                                                            style: TextStyle(
                                                              color: Colors.orange,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.delete_outline, color: Colors.red),
                                                      onPressed: () => _removerItem(item),
                                                      style: IconButton.styleFrom(
                                                        padding: EdgeInsets.all(4),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total:",
                                                style: TextStyle(
                                                  color: Cores.textWhite,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "R\$ ${_totalPedido.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                SizedBox(height: 16),

                                // Observação
                                Text(
                                  "Observações",
                                  style: TextStyle(
                                    color: Cores.textWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: obsController,
                                  maxLines: 3,
                                  style: TextStyle(color: Cores.textWhite),
                                  decoration: InputDecoration(
                                    hintText: "Observações do pedido...",
                                    hintStyle: TextStyle(color: Cores.textGray),
                                    filled: true,
                                    fillColor: Cores.cardBlack,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Cores.borderGray),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Cores.borderGray),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.orange),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Cores.cardBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Cores.borderGray.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            color: Cores.textGray,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              "Salvar Alterações",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
