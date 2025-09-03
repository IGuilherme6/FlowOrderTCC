import 'package:floworder/controller/CardapioController.dart';
import 'package:floworder/controller/MesaController.dart';
import 'package:floworder/models/ItemCardapio.dart';
import 'package:flutter/material.dart';
import 'package:floworder/controller/PedidoController.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:floworder/models/Mesa.dart';
import 'package:floworder/view/BarraLateral.dart';
import '../auxiliar/Cores.dart';
import '../models/Cardapio.dart';

class TelaCaixa extends StatefulWidget {
  @override
  State<TelaCaixa> createState() => _TelaCaixaState();
}

class _TelaCaixaState extends State<TelaCaixa> {
  Stream<List<Pedido>>? _pedidosStream;
  final PedidoController _pedidoController = PedidoController();
  String _filtroStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    _inicializarStream();
  }

  Future<void> _inicializarStream() async {
    try {
      final stream = await _pedidoController.listarPedidosTempoReal();
      setState(() {
        _pedidosStream = stream;
      });
    } catch (e) {
      print('Erro ao inicializar stream: $e');
      // Tratar erro aqui
    }
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
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildFiltros(),
                  SizedBox(height: 16),
                  Expanded(
                    child: _pedidosStream == null
                        ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Cores.primaryRed),
                      ),
                    )
                        : StreamBuilder<List<Pedido>>(
                      stream: _pedidosStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Cores.primaryRed),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Erro: ${snapshot.error}'),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        final pedidos = _filtrarPedidos(snapshot.data!);
                        return ListView.builder(
                          itemCount: pedidos.length,
                          itemBuilder: (context, index) {
                            final pedido = pedidos[index];
                            return _buildPedidoCard(pedido);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdicionarPedidoDialog(),
        backgroundColor: Cores.primaryRed,
        icon: Icon(Icons.add, color: Cores.textWhite),
        label: Text(
          'Novo Pedido',
          style: TextStyle(color: Cores.textWhite),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Caixa',
          style: TextStyle(
            color: Cores.textWhite,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Cores.cardBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Cores.borderGray),
          ),
          child: Row(
            children: [
              Icon(Icons.restaurant_menu, color: Cores.primaryRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Sistema de Pedidos',
                style: TextStyle(color: Cores.textGray, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    final filtros = ['Todos', ...Pedido.statusOpcoes];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final isSelected = _filtroStatus == filtro;

          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filtro),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroStatus = filtro;
                });
              },
              backgroundColor: Cores.cardBlack,
              selectedColor: Cores.primaryRed,
              labelStyle: TextStyle(
                color: isSelected ? Cores.textWhite : Cores.textGray,
              ),
              side: BorderSide(color: Cores.borderGray),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Cores.textGray),
          SizedBox(height: 16),
          Text(
            'Nenhum pedido encontrado',
            style: TextStyle(color: Cores.textGray, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Clique no botão "+" para criar um novo pedido',
            style: TextStyle(color: Cores.textGray, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {
    final total = pedido.calcularTotal();

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Cores.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.borderGray),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(16),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Cores.primaryRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Mesa ${pedido.mesa.numero}${pedido.mesa.nome.isNotEmpty ? ' - ${pedido.mesa.nome}' : ''}',
                style: TextStyle(
                  color: Cores.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Total: R\$ ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Cores.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusChip(pedido.statusAtual),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Horário: ${_formatarHorario(pedido.horario)} - ${pedido.itens.length} itens',
                style: TextStyle(color: Cores.textGray, fontSize: 12),
              ),
            ),
            if (pedido.observacao != null && pedido.observacao!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Obs: ${pedido.observacao}',
                  style: TextStyle(color: Cores.textGray.withOpacity(0.8), fontSize: 11),
                ),
              ),
          ],
        ),
        iconColor: Cores.textWhite,
        collapsedIconColor: Cores.textGray,
        children: [
          _buildItensSection(pedido),
          SizedBox(height: 16),
          _buildActionsSection(pedido),
        ],
      ),
    );
  }

  String _formatarHorario(DateTime horario) {
    return '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItensSection(Pedido pedido) {
    // Agrupando itens iguais para mostrar quantidade
    Map<String, Map<String, dynamic>> itensAgrupados = {};

    for (var item in pedido.itens) {
      String chave = '${item.nome}-${item.preco}';
      if (itensAgrupados.containsKey(chave)) {
        itensAgrupados[chave]!['quantidade']++;
      } else {
        itensAgrupados[chave] = {
          'item': item,
          'quantidade': 1,
        };
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.backgroundBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Cores.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Itens do Pedido',
                style: TextStyle(
                  color: Cores.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pedido.statusAtual == 'Aberto') // Só permite adicionar itens se o pedido estiver aberto
                TextButton.icon(
                  onPressed: () => _showAdicionarItensDialog(pedido),
                  icon: Icon(Icons.add, size: 16, color: Cores.primaryRed),
                  label: Text(
                    'Adicionar Itens',
                    style: TextStyle(color: Cores.primaryRed, fontSize: 12),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          ...itensAgrupados.values.map((itemData) {
            ItemCardapio item = itemData['item'];
            int quantidade = itemData['quantidade'];
            double subtotal = item.preco * quantidade;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Cores.cardBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.all(12),
                childrenPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                title: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Cores.primaryRed,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          quantidade.toString(),
                          style: TextStyle(
                            color: Cores.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nome,
                            style: TextStyle(color: Cores.textWhite, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            item.categoria,
                            style: TextStyle(color: Cores.textGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Cores.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (quantidade > 1)
                          Text(
                            '${quantidade}x R\$ ${item.preco.toStringAsFixed(2)}',
                            style: TextStyle(color: Cores.textGray, fontSize: 10),
                          ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.info_outline,
                      color: Cores.textGray,
                      size: 16,
                    ),
                  ],
                ),
                iconColor: Cores.textGray,
                collapsedIconColor: Cores.textGray,
                children: [
                  // Buscar descrição do cardápio original ou mostrar informações básicas
                  FutureBuilder<String>(
                    future: _buscarDescricaoItem(item),
                    builder: (context, snapshot) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Cores.backgroundBlack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Cores.borderGray.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalhes do Item:',
                              style: TextStyle(
                                color: Cores.textWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              snapshot.data ?? 'Carregando descrição...',
                              style: TextStyle(
                                color: Cores.textGray,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Preço unitário: R\$ ${item.preco.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Cores.textGray,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Categoria: ${item.categoria}',
                                  style: TextStyle(
                                    color: Cores.textGray,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<String> _buscarDescricaoItem(ItemCardapio item) async {
    try {
      final cardapioController = CardapioController();
      final cardapios = await cardapioController.buscarCardapios();

      // Buscar o cardápio correspondente ao item
      final cardapioEncontrado = cardapios.firstWhere(
            (cardapio) => cardapio.nome == item.nome && cardapio.preco == item.preco,
        orElse: () => Cardapio(
          nome: item.nome,
          descricao: 'Item do pedido - descrição não disponível',
          preco: item.preco,
          categoria: item.categoria,
        ),
      );

      return cardapioEncontrado.descricao.isNotEmpty
          ? cardapioEncontrado.descricao
          : 'Sem descrição disponível para este item.';
    } catch (e) {
      return 'Erro ao carregar descrição do item.';
    }
  }

  Widget _buildActionsSection(Pedido pedido) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Pedido.statusOpcoes.map((status) {
            final isSelected = pedido.statusAtual == status;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Cores.primaryRed : Cores.darkRed,
                foregroundColor: Cores.textWhite,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                if (pedido.uid != null && !isSelected) {
                  await _pedidoController.atualizarStatusPedido(pedido.uid!, status);
                }
              },
              child: Text(status, style: TextStyle(fontSize: 12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Pedido> _filtrarPedidos(List<Pedido> pedidos) {
    if (_filtroStatus == 'Todos') return pedidos;
    return pedidos.where((p) => p.statusAtual == _filtroStatus).toList();
  }

  void _showAdicionarPedidoDialog() {
    showDialog(
      context: context,
      builder: (context) => AdicionarPedidoDialog(),
    );
  }

  void _showAdicionarItensDialog(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AdicionarItensDialog(pedido: pedido),
    );
  }
}

// ============================
// Dialog para adicionar novo pedido
// ============================
class AdicionarPedidoDialog extends StatefulWidget {
  @override
  _AdicionarPedidoDialogState createState() => _AdicionarPedidoDialogState();
}

class _AdicionarPedidoDialogState extends State<AdicionarPedidoDialog> {
  final PedidoController _pedidoController = PedidoController();
  final MesaController _mesaController = MesaController();
  final CardapioController _cardapioController = CardapioController();
  final TextEditingController _observacaoController = TextEditingController();

  Mesa? mesaSelecionada;
  List<Cardapio> _itensCardapio = []; // Mudou de ItemCardapio para Cardapio
  List<Mesa> _mesas = [];
  Map<Cardapio, int> _itensSelecionados = {}; // Mudou de ItemCardapio para Cardapio
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final mesas = await _mesaController.buscarMesas();
      final cardapios = await _cardapioController.buscarCardapios();

      setState(() {
        _mesas = mesas;
        _itensCardapio = cardapios.where((item) => item.ativo).toList(); // Só itens ativos
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar dados: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selecionarMesa(Mesa mesa) {
    setState(() {
      mesaSelecionada = mesaSelecionada?.uid == mesa.uid ? null : mesa;
    });
  }

  void _alterarQuantidadeItem(Cardapio item, int quantidade) {
    setState(() {
      if (quantidade <= 0) {
        _itensSelecionados.remove(item);
      } else {
        _itensSelecionados[item] = quantidade;
      }
    });
  }

  double get _totalPedido {
    return _itensSelecionados.entries.fold<double>(
        0,
            (sum, entry) => sum + (entry.key.preco * entry.value)
    );
  }

  // Converte Cardapio para ItemCardapio para compatibilidade com Pedido
  List<ItemCardapio> get _itensParaPedido {
    List<ItemCardapio> itens = [];
    _itensSelecionados.forEach((cardapio, quantidade) {
      for (int i = 0; i < quantidade; i++) {
        itens.add(ItemCardapio(
          uid: cardapio.uid,
          nome: cardapio.nome,
          preco: cardapio.preco,
          categoria: cardapio.categoria,
        ));
      }
    });
    return itens;
  }

  Future<void> _salvarPedido() async {
    if (mesaSelecionada == null || _itensSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecione uma mesa e pelo menos um item"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Criar a lista de itens do cardápio selecionados
      List<ItemCardapio> itensPedido = _itensParaPedido;

      // Criar o pedido com os itens do cardápio
      final pedido = Pedido(
        horario: DateTime.now(),
        mesa: mesaSelecionada!,
        itens: itensPedido,
        statusAtual: 'Aberto',
        observacao: _observacaoController.text.trim(),
      );

      // Salvar o pedido - corrigido para usar apenas o pedido
      await _pedidoController.cadastrarPedido(pedido);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pedido criado com sucesso! ${itensPedido.length} itens adicionados."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar pedido: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Cores.cardBlack,
      title: Text(
        'Novo Pedido',
        style: TextStyle(color: Cores.textWhite),
      ),
      content: Container(
        width: 600,
        height: 700,
        child: _carregando
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Cores.primaryRed),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seleção de Mesa
                    Text(
                      "Selecione a Mesa:",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_mesas.isEmpty)
                      Text(
                        "Nenhuma mesa encontrada",
                        style: TextStyle(color: Cores.textGray),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _mesas.map((mesa) {
                          final isSelected = mesaSelecionada?.uid == mesa.uid;
                          return FilterChip(
                            label: Text("Mesa ${mesa.numero}${mesa.nome.isNotEmpty ? ' - ${mesa.nome}' : ''}"),
                            selected: isSelected,
                            onSelected: (_) => _selecionarMesa(mesa),
                            backgroundColor: Cores.backgroundBlack,
                            selectedColor: Cores.primaryRed,
                            labelStyle: TextStyle(
                              color: isSelected ? Cores.textWhite : Cores.textGray,
                            ),
                            side: BorderSide(color: Cores.borderGray),
                          );
                        }).toList(),
                      ),

                    SizedBox(height: 24),

                    // Seleção de Itens
                    Text(
                      "Itens do Cardápio:",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_itensCardapio.isEmpty)
                      Text(
                        "Nenhum item encontrado",
                        style: TextStyle(color: Cores.textGray),
                      )
                    else
                      ..._itensCardapio.map((item) {
                        final quantidade = _itensSelecionados[item] ?? 0;
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: quantidade > 0
                                ? Cores.primaryRed.withOpacity(0.1)
                                : Cores.backgroundBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: quantidade > 0
                                  ? Cores.primaryRed
                                  : Cores.borderGray,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.nome,
                                          style: TextStyle(
                                            color: Cores.textWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "R\$ ${item.preco.toStringAsFixed(2)} - ${item.categoria}",
                                          style: TextStyle(color: Cores.textGray),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: quantidade > 0
                                            ? () => _alterarQuantidadeItem(item, quantidade - 1)
                                            : null,
                                        icon: Icon(Icons.remove, color: Cores.textWhite, size: 16),
                                        style: IconButton.styleFrom(
                                          backgroundColor: quantidade > 0 ? Cores.darkRed : Cores.textGray,
                                          minimumSize: Size(35, 35),
                                        ),
                                      ),
                                      Container(
                                        width: 45,
                                        height: 35,
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Cores.cardBlack,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Cores.borderGray),
                                        ),
                                        child: Text(
                                          quantidade.toString(),
                                          style: TextStyle(
                                            color: Cores.textWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _alterarQuantidadeItem(item, quantidade + 1),
                                        icon: Icon(Icons.add, color: Cores.textWhite, size: 16),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Cores.primaryRed,
                                          minimumSize: Size(35, 35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Descrição expandível
                              if (item.descricao.isNotEmpty) ...[
                                SizedBox(height: 8),
                                InkWell(
                                  //onTap: () => _mostrarDescricaoCompleta(item),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Cores.cardBlack,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Cores.borderGray.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.descricao,
                                            style: TextStyle(
                                              color: Cores.textGray,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.info_outline,
                                          color: Cores.textGray,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),

                    SizedBox(height: 24),

                    // Campo de Observação
                    Text(
                      "Observações:",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _observacaoController,
                      maxLines: 3,
                      style: TextStyle(color: Cores.textWhite),
                      decoration: InputDecoration(
                        hintText: "Observações do pedido (opcional)...",
                        hintStyle: TextStyle(color: Cores.textGray),
                        filled: true,
                        fillColor: Cores.backgroundBlack,
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

            // Resumo e Total
            if (_itensSelecionados.isNotEmpty) ...[
              Divider(color: Cores.borderGray),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Cores.backgroundBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Cores.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resumo do Pedido:",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._itensSelecionados.entries.map((entry) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${entry.value}x ${entry.key.nome}",
                              style: TextStyle(color: Cores.textGray),
                            ),
                          ),
                          Text(
                            "R\$ ${(entry.key.preco * entry.value).toStringAsFixed(2)}",
                            style: TextStyle(color: Cores.textWhite),
                          ),
                        ],
                      ),
                    )),
                    Divider(color: Cores.borderGray),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total:",
                          style: TextStyle(
                            color: Cores.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: Cores.textGray)),
        ),
        ElevatedButton(
          onPressed: (_carregando || mesaSelecionada == null || _itensSelecionados.isEmpty)
              ? null
              : _salvarPedido,
          style: ElevatedButton.styleFrom(
            backgroundColor: Cores.primaryRed,
            disabledBackgroundColor: Cores.textGray,
          ),
          child: Text('Salvar Pedido', style: TextStyle(color: Cores.textWhite)),
        ),
      ],
    );
  }


}


// ============================
// Dialog para adicionar itens a pedido existente
// ============================
class AdicionarItensDialog extends StatefulWidget {
  final Pedido pedido;

  AdicionarItensDialog({required this.pedido});

  @override
  _AdicionarItensDialogState createState() => _AdicionarItensDialogState();
}

class _AdicionarItensDialogState extends State<AdicionarItensDialog> {
  final PedidoController _pedidoController = PedidoController();
  final CardapioController _cardapioController = CardapioController();

  List<Cardapio> _itensCardapio = [];
  Map<Cardapio, int> _itensSelecionados = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarItensCardapio();
  }

  Future<void> _carregarItensCardapio() async {
    try {
      final cardapios = await _cardapioController.buscarCardapios();

      setState(() {
        _itensCardapio = cardapios.where((item) => item.ativo).toList();
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar itens: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _alterarQuantidadeItem(Cardapio item, int quantidade) {
    setState(() {
      if (quantidade <= 0) {
        _itensSelecionados.remove(item);
      } else {
        _itensSelecionados[item] = quantidade;
      }
    });
  }

  double get _totalNovosItens {
    return _itensSelecionados.entries.fold<double>(
        0, (sum, entry) => sum + (entry.key.preco * entry.value));
  }

  double get _totalPedidoAtualizado {
    return widget.pedido.calcularTotal() + _totalNovosItens;
  }

  List<ItemCardapio> get _novosItensParaPedido {
    List<ItemCardapio> itens = [];
    _itensSelecionados.forEach((cardapio, quantidade) {
      for (int i = 0; i < quantidade; i++) {
        itens.add(ItemCardapio(
          uid: cardapio.uid,
          nome: cardapio.nome,
          preco: cardapio.preco,
          categoria: cardapio.categoria,
        ));
      }
    });
    return itens;
  }

  Future<void> _adicionarItensAoPedido() async {
    if (_itensSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecione pelo menos um item para adicionar"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      List<ItemCardapio> novosItens = _novosItensParaPedido;
      List<ItemCardapio> itensAtualizados = [...widget.pedido.itens, ...novosItens];

      // Atualizar o pedido no Firebase
      await _pedidoController.atualizarItensPedido(widget.pedido.uid!, itensAtualizados);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${novosItens.length} itens adicionados ao pedido com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao adicionar itens: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Cores.cardBlack,
      title: Row(
        children: [
          Icon(Icons.add_shopping_cart, color: Cores.primaryRed),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar Itens',
                  style: TextStyle(color: Cores.textWhite, fontSize: 18),
                ),
                Text(
                  'Mesa ${widget.pedido.mesa.numero}',
                  style: TextStyle(color: Cores.textGray, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: 500,
        height: 600,
        child: _carregando
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Cores.primaryRed),
          ),
        )
            : Column(
          children: [
            // Resumo do pedido atual
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Cores.backgroundBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Cores.borderGray),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total atual do pedido:',
                    style: TextStyle(color: Cores.textGray, fontSize: 14),
                  ),
                  Text(
                    'R\$ ${widget.pedido.calcularTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Lista de itens disponíveis
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selecione os itens para adicionar:",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_itensCardapio.isEmpty)
                      Text(
                        "Nenhum item encontrado",
                        style: TextStyle(color: Cores.textGray),
                      )
                    else
                      ..._itensCardapio.map((item) {
                        final quantidade = _itensSelecionados[item] ?? 0;
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: quantidade > 0
                                ? Cores.primaryRed.withOpacity(0.1)
                                : Cores.backgroundBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: quantidade > 0
                                  ? Cores.primaryRed
                                  : Cores.borderGray,
                            ),
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
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "R\$ ${item.preco.toStringAsFixed(2)} - ${item.categoria}",
                                      style: TextStyle(color: Cores.textGray),
                                    ),
                                    if (item.descricao.isNotEmpty)
                                      Text(
                                        item.descricao,
                                        style: TextStyle(
                                          color: Cores.textGray.withOpacity(0.7),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: quantidade > 0
                                        ? () => _alterarQuantidadeItem(item, quantidade - 1)
                                        : null,
                                    icon: Icon(Icons.remove, color: Cores.textWhite, size: 16),
                                    style: IconButton.styleFrom(
                                      backgroundColor: quantidade > 0 ? Cores.darkRed : Cores.textGray,
                                      minimumSize: Size(32, 32),
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 32,
                                    alignment: Alignment.center,
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Cores.cardBlack,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Cores.borderGray),
                                    ),
                                    child: Text(
                                      quantidade.toString(),
                                      style: TextStyle(
                                        color: Cores.textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _alterarQuantidadeItem(item, quantidade + 1),
                                    icon: Icon(Icons.add, color: Cores.textWhite, size: 16),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Cores.primaryRed,
                                      minimumSize: Size(32, 32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),

            // Resumo dos itens selecionados
            if (_itensSelecionados.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Cores.backgroundBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Cores.primaryRed),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Novos itens selecionados:",
                      style: TextStyle(
                        color: Cores.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._itensSelecionados.entries.map((entry) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${entry.value}x ${entry.key.nome}",
                              style: TextStyle(color: Cores.textGray, fontSize: 12),
                            ),
                          ),
                          Text(
                            "R\$ ${(entry.key.preco * entry.value).toStringAsFixed(2)}",
                            style: TextStyle(color: Cores.textWhite, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
                    Divider(color: Cores.borderGray),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Novo total:",
                          style: TextStyle(
                            color: Cores.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "R\$ ${_totalPedidoAtualizado.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Cores.primaryRed,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: Cores.textGray)),
        ),
        ElevatedButton(
          onPressed: (_carregando || _itensSelecionados.isEmpty)
              ? null
              : _adicionarItensAoPedido,
          style: ElevatedButton.styleFrom(
            backgroundColor: Cores.primaryRed,
            disabledBackgroundColor: Cores.textGray,
          ),
          child: Text('Adicionar Itens', style: TextStyle(color: Cores.textWhite)),
        ),
      ],
    );
  }
}