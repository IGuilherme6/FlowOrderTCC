import 'package:flutter/material.dart';
import 'package:floworder/controller/PedidoController.dart';
import 'package:floworder/models/Pedido.dart';
import '../auxiliar/Cores.dart';
import 'BarraLateral.dart';
import '../models/GlobalUser.dart';

class TelaPedidos extends StatefulWidget {
  @override
  State<TelaPedidos> createState() => _TelaPedidosState();
}

class _TelaPedidosState extends State<TelaPedidos> {
  final PedidoController _pedidoController = PedidoController();
  Future<Stream<List<Pedido>>>? _pedidosFuture;

  // Variável de estado para controlar visibilidade da senha
  bool _obscureSenhaGerente = true;

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
          Barralateral(currentRoute: '/pedidos'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedidos',
                    style: TextStyle(
                      color: Cores.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: _buildPedidosArea()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosArea() {
    return FutureBuilder<Stream<List<Pedido>>>(
      future: _pedidosFuture,
      builder: (context, futureSnap) {
        if (futureSnap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Cores.primaryRed));
        }
        if (futureSnap.hasError) {
          return Center(child: Text("Erro: ${futureSnap.error}", style: TextStyle(color: Cores.textGray)));
        }
        if (!futureSnap.hasData) {
          return _buildEmptyState();
        }

        return StreamBuilder<List<Pedido>>(
          stream: futureSnap.data,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Cores.primaryRed));
            }
            if (snap.hasError) {
              return Center(child: Text("Erro: ${snap.error}", style: TextStyle(color: Cores.textGray)));
            }
            if (!snap.hasData || snap.data!.isEmpty) return _buildEmptyState();

            final pedidos = snap.data!;
            return ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, i) => _buildPedidoCard(pedidos[i]),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Cores.textGray),
          const SizedBox(height: 16),
          Text('Nenhum pedido encontrado',
              style: TextStyle(color: Cores.textGray, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {
    final total = pedido.calcularTotal();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Cores.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.borderGray),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Cores.primaryRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Mesa ${pedido.mesa.numero}',
                style: TextStyle(color: Cores.textWhite, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Total: R\$ ${total.toStringAsFixed(2)}',
                  style: TextStyle(color: Cores.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildStatusChip(pedido.statusAtual),
          ],
        ),
        subtitle: Text(
          'Itens: ${pedido.itens.length} - Horário: ${_formatarHorario(pedido.horario)}',
          style: TextStyle(color: Cores.textGray, fontSize: 12),
        ),
        children: [
          ...pedido.itens.map(
                (item) => ListTile(
              dense: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item.quantidade}x ${item.nome}",
                    style: TextStyle(color: Cores.textWhite),
                  ),
                  if (item.observacao != null && item.observacao!.isNotEmpty)
                    Text(
                      "OBS: "+item.observacao!,
                      style: TextStyle(color: Cores.primaryRed, fontSize: 12),
                    ),
                ],
              ),
              subtitle: Text(
                item.categoria,
                style: TextStyle(color: Cores.textGray),
              ),
              trailing: Text(
                "R\$ ${(item.preco * item.quantidade).toStringAsFixed(2)}",
                style: TextStyle(color: Cores.primaryRed),
              ),
            ),
          ),
          if (pedido.observacao != null && pedido.observacao!.isNotEmpty)
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
          const SizedBox(height: 8),
          _buildStatusActions(pedido),
        ],
      ),
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
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusActions(Pedido pedido) {
    final opcoes = ['Aberto', 'Em Preparo', 'Pronto', 'Entregue', 'Cancelado'];

    return Wrap(
      spacing: 8,
      children: opcoes.map((status) {
        final selected = pedido.statusAtual == status;

        // Permite cancelar de qualquer status, exceto se já estiver cancelado
        final podeInteragir = !selected || (status == 'Cancelado' && !selected);

        return ChoiceChip(
          label: Text(status),
          selected: selected,
          selectedColor: Cores.primaryRed,
          onSelected: podeInteragir ? (value) async {
            if (!selected) {
              // Se o status for "Cancelado", mostra diálogo com campo de texto
              if (status == 'Cancelado') {
                final TextEditingController senhaGerenteController = TextEditingController();

                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => StatefulBuilder(
                    builder: (context, setStateDialog) => AlertDialog(
                      backgroundColor: Cores.cardBlack,
                      title: Text(
                        "Cancelar Pedido",
                        style: TextStyle(color: Cores.textWhite),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tem certeza que deseja cancelar este pedido da mesa ${pedido.mesa.numero}?",
                            style: TextStyle(fontSize: 14, color: Cores.textGray),
                          ),
                          SizedBox(height: 16),
                          _buildInputField(
                            controller: senhaGerenteController,
                            label: "Senha do Gerente",
                            icon: Icons.password,
                            obscureText: _obscureSenhaGerente,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureSenhaGerente ? Icons.visibility : Icons.visibility_off,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureSenhaGerente = !_obscureSenhaGerente;
                                });
                                setStateDialog(() {});
                              },
                            ),
                          )
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: Text("Voltar", style: TextStyle(color: Cores.textGray)),
                          onPressed: () {
                            senhaGerenteController.dispose();
                            Navigator.pop(context, false);
                          },
                        ),
                        ElevatedButton(
                          child: Text("Confirmar Cancelamento"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        ),
                      ],
                    ),
                  ),
                );

                // Se não confirmou, não faz nada
                if (confirmar != true) {
                  senhaGerenteController.dispose();
                  return;
                }

                final res = await _pedidoController.confirmarSenhaCancelar(pedido, senhaGerenteController.text);
                senhaGerenteController.dispose();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Para outros status, apenas atualiza normalmente
              final sucesso = await _pedidoController.mudarStatusPedido(pedido.uid!, status);
              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Status atualizado para $status"),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {}); // força atualização
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erro ao atualizar status"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } : null, // Desabilita se não puder interagir
        );
      }).toList(),
    );
  }

  String _formatarHorario(DateTime horario) {
    return '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.red),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelStyle: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}