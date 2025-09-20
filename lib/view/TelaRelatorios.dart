import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:floworder/view/BarraLateral.dart';
import 'package:floworder/auxiliar/Cores.dart';
import 'package:floworder/models/Pedido.dart';
import 'package:floworder/firebase/CardapioFirebase.dart';

import '../firebase/RelatorioService.dart';
import '../firebase/UsuarioFirebase.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final RelatorioService _relatorioService = RelatorioService();
  final UsuarioFirebase _user = UsuarioFirebase();


  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _tipoRelatorio = 'vendas_detalhado';
  String _statusFiltro = 'todos';

  bool _carregando = false;

  final DateFormat _formatoData = DateFormat('dd/MM/yyyy');
  final DateFormat _formatoDataHora = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _formatoMoeda =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _dataFim = DateTime.now();
    _dataInicio = _dataFim!.subtract(const Duration(days: 30));
  }

  /// Método principal: busca dados e gera PDF na hora (não tem mais botão buscar separado)
  Future<void> _gerarEImprimirRelatorio() async {
    setState(() => _carregando = true);

    try {
      // 1) obter gerenteUid do usuário logado
      final gerenteUid = _user.pegarIdUsuarioLogado() as String;
      if (gerenteUid == null || gerenteUid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Gerente não encontrado'), backgroundColor: Cores.primaryRed),
        );
        return;
      }

      // 2) chamar service para montar dados
      final dados = await _relatorioService.gerarRelatorio(
        gerenteUid: gerenteUid,
        tipo: _tipoRelatorio,
        inicio: _dataInicio,
        fim: _dataFim,
        status: _statusFiltro,
      );

      // 3) se não tiver dados
      final temDados = (dados.isNotEmpty && dados.values.any((v) => v != null && v is List ? (v as List).isNotEmpty : true));
      if (!temDados) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Nenhum dado encontrado para os filtros selecionados'), backgroundColor: Cores.primaryRed),
        );
        return;
      }

      // 4) montar PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            return [
              _buildCabecalhoPDF(),
              if (_tipoRelatorio == 'vendas_geral')
                _buildResumoPDF(dados['resumo'] as Map<String, dynamic>)
              else if (_tipoRelatorio == 'vendas_detalhado')
                _buildTabelaPedidosPDF(dados['pedidos'] as List)
              else if (_tipoRelatorio == 'pagamentos')
                  _buildTabelaPagamentosPDF(dados['pagamentos'] as List)
                else if (_tipoRelatorio == 'produtos')
                    _buildTabelaProdutosPDF(dados['produtos'] as List),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e, st) {
      debugPrint('Erro ao gerar PDF: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e'), backgroundColor: Cores.primaryRed),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  // ---------- PDF helpers ----------
  pw.Widget _buildCabecalhoPDF() {
    String titulo = 'Relatório: ';
    switch (_tipoRelatorio) {
      case 'vendas_geral':
        titulo += 'Vendas Geral';
        break;
      case 'vendas_detalhado':
        titulo += 'Vendas Detalhado ${_statusFiltro != 'todos' ? _statusFiltro : ''}';
        break;
      case 'pagamentos':
        titulo += 'Relatório de Pagamentos';
        break;
      case 'produtos':
        titulo += 'Produtos Mais Vendidos';
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text('Período: ${_formatoData.format(_dataInicio!)} até ${_formatoData.format(_dataFim!)}'),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildResumoPDF(Map<String, dynamic> resumo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Resumo Geral', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Total de pedidos: ${resumo['totalPedidos']}'),
        pw.Text('Total de vendas: ${_formatoMoeda.format(resumo['totalVendas'])}'),
        pw.Text('Ticket médio: ${_formatoMoeda.format(resumo['ticketMedio'])}'),
      ],
    );
  }

  pw.Widget _buildTabelaPedidosPDF(List pedidos) {
    return pw.TableHelper.fromTextArray(
      headers: ['Data/Hora', 'Mesa', 'Status', 'Itens', 'Total'],
      data: pedidos.map((p) {
        final pedido = p['pedido'] as Pedido;
        final mesaNome = p['mesaNome'] as String;
        final itensStr = pedido.itens.map((i) => '${i.nome} x${i.quantidade}').join('\n');
        return [
          _formatoDataHora.format(pedido.horario),
          mesaNome,
          pedido.statusAtual,
          itensStr,
          _formatoMoeda.format(pedido.calcularTotal()),
        ];
      }).toList(),
      headerDecoration: pw.BoxDecoration(color: PdfColors.red900),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      cellStyle: pw.TextStyle(fontSize: 10),
    );
  }

  pw.Widget _buildTabelaPagamentosPDF(List pagamentos) {
    return pw.TableHelper.fromTextArray(
      headers: ['Pedido', 'Mesa', 'Método', 'Valor', 'Desconto', 'Troco'],
      data: pagamentos.map((m) {
        final pedido = m['pedido'] as Pedido;
        final mesaNome = m['mesaNome'] as String;
        final pag = m['pagamento'] as Map<String, dynamic>;
        return [
          pedido.uid ?? '',
          mesaNome,
          pag['metodoPagamento'] ?? '',
          _formatoMoeda.format((pag['valorPago'] ?? 0).toDouble()),
          _formatoMoeda.format((pag['desconto'] ?? 0).toDouble()),
          _formatoMoeda.format((pag['troco'] ?? 0).toDouble()),
        ];
      }).toList(),
      headerDecoration: pw.BoxDecoration(color: PdfColors.red900),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      cellStyle: pw.TextStyle(fontSize: 10),
    );
  }

  pw.Widget _buildTabelaProdutosPDF(List produtos) {
    // produtos é uma lista de MapEntry (nome, quantidade) na service
    final rows = produtos.map((e) {
      if (e is MapEntry) return [e.key, e.value.toString()];
      if (e is List && e.length >= 2) return [e[0].toString(), e[1].toString()];
      return [e.toString(), ''];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Produto', 'Quantidade'],
      data: rows,
      headerDecoration: pw.BoxDecoration(color: PdfColors.red900),
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      border: pw.TableBorder.all(color: PdfColors.grey300),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.backgroundBlack,
      body: Row(
        children: [
          Barralateral(currentRoute: '/relatorios'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Relatórios', style: TextStyle(color: Cores.textWhite, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildFiltros(),
                const SizedBox(height: 24),
                _buildBotoesAcao(),
                const SizedBox(height: 12),
                if (_carregando) Center(child: CircularProgressIndicator(color: Cores.primaryRed)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Cores.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: Cores.borderGray)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Filtros', style: TextStyle(color: Cores.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Tipo relatório
        DropdownButton<String>(
          value: _tipoRelatorio,
          isExpanded: true,
          dropdownColor: Cores.cardBlack,
          style: TextStyle(color: Cores.textWhite),
          underline: Container(),
          items: const [
            DropdownMenuItem(value: 'vendas_geral', child: Text('Vendas - Geral')),
            DropdownMenuItem(value: 'vendas_detalhado', child: Text('Vendas - Detalhado')),
            DropdownMenuItem(value: 'pagamentos', child: Text('Relatório de Pagamentos')),
            DropdownMenuItem(value: 'produtos', child: Text('Produtos Mais Vendidos')),
          ],
          onChanged: (v) => setState(() {
            _tipoRelatorio = v!;
            // reset status ao trocar tipo
            if (_tipoRelatorio != 'vendas_detalhado') _statusFiltro = 'todos';
          }),
        ),
        const SizedBox(height: 16),

        // Datas
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _dataInicio ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (picked != null) setState(() => _dataInicio = picked);
              },
              child: _buildCampoFiltro('Data Início', _dataInicio != null ? _formatoData.format(_dataInicio!) : 'Selecionar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _dataFim ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (picked != null) setState(() => _dataFim = picked);
              },
              child: _buildCampoFiltro('Data Fim', _dataFim != null ? _formatoData.format(_dataFim!) : 'Selecionar'),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Status (só em detalhado)
        if (_tipoRelatorio == 'vendas_detalhado')
          DropdownButton<String>(
            value: _statusFiltro,
            isExpanded: true,
            dropdownColor: Cores.cardBlack,
            style: TextStyle(color: Cores.textWhite),
            underline: Container(),
            items: const [
              DropdownMenuItem(value: 'todos', child: Text('Todos')),
              DropdownMenuItem(value: 'Entregue', child: Text('Entregue')),
              DropdownMenuItem(value: 'Cancelado', child: Text('Cancelado')),
            ],
            onChanged: (v) => setState(() => _statusFiltro = v!),
          ),
      ]),
    );
  }

  Widget _buildCampoFiltro(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: Cores.backgroundBlack, borderRadius: BorderRadius.circular(8), border: Border.all(color: Cores.borderGray)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Cores.textGray)),
        Text(valor, style: TextStyle(color: Cores.textWhite)),
      ]),
    );
  }

  Widget _buildBotoesAcao() {
    return Row(children: [
      ElevatedButton.icon(
        onPressed: _carregando ? null : _gerarEImprimirRelatorio,
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text('Gerar PDF', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Cores.primaryRed),
      ),
    ]);
  }
}
